"""
AI ocena przetargu — przez Superbee LLM.
Patrzy na aktywne budowy i moce przerobowe firmy.
"""
import asyncio
import json
import logging
from dataclasses import dataclass
from typing import Optional

logger = logging.getLogger(__name__)


@dataclass
class OcenaPrzetargu:
    score: int  # 0-100
    czy_warto: bool
    uzasadnienie: str
    uwagi: list[str]  # krótkie alerty np. "Krótki termin (3 dni)", "Duże obciążenie"
    rekomendacja_emma: str  # gotowy tekst dla Emmy do wysłania do Romana


async def _call_llm(prompt: str, system: str) -> str:
    """Wywołanie Superbee LLM. Fallback na prosty heurystyczny wynik."""
    try:
        import httpx

        async with httpx.AsyncClient(timeout=60) as client:
            resp = await client.post(
                "http://127.0.0.1:8002/api/llm/chat",
                json={
                    "model": "default",
                    "messages": [
                        {"role": "system", "content": system},
                        {"role": "user", "content": prompt},
                    ],
                    "response_format": {"type": "json_object"},
                },
            )
            resp.raise_for_status()
            data = resp.json()
            return data.get("content") or data.get("message", {}).get("content", "{}")
    except Exception as e:
        logger.warning("Superbee LLM niedostępny: %s — używam heurystyki", e)
        return ""


def _heurystyczna_ocena(przetarg_data: dict, kontekst: dict) -> OcenaPrzetargu:
    """Prosta heurystyka gdy LLM niedostępny."""
    import decimal
    from datetime import datetime, timezone

    score = 50
    uwagi = []
    czy_warto = True

    # Termin składania
    termin = przetarg_data.get("termin_skladania")
    if termin:
        if isinstance(termin, str):
            try:
                termin = datetime.fromisoformat(termin.replace("Z", "+00:00"))
            except Exception:
                termin = None

    if termin:
        dni = (termin - datetime.now(timezone.utc)).days
        if dni < 3:
            score -= 30
            uwagi.append(f"Bardzo krótki termin składania ({dni} dni)")
            czy_warto = False
        elif dni < 7:
            score -= 15
            uwagi.append(f"Krótki termin składania ({dni} dni)")

    # Wartość
    wartosc = przetarg_data.get("wartosc_szacunkowa")
    if wartosc:
        try:
            w = float(wartosc)
            if w < 50_000:
                score -= 10
                uwagi.append("Mała wartość zamówienia")
            elif w > 2_000_000:
                score += 10
                uwagi.append("Duże zamówienie — warto rozważyć")
        except Exception:
            pass

    # Obciążenie firmy
    aktywne_budowy = kontekst.get("aktywne_budowy", 0)
    if aktywne_budowy >= 5:
        score -= 20
        uwagi.append(f"Wysokie obciążenie firmy ({aktywne_budowy} aktywnych budów)")
        czy_warto = False
    elif aktywne_budowy >= 3:
        score -= 5
        uwagi.append(f"Umiarkowane obciążenie ({aktywne_budowy} aktywnych budów)")

    score = max(0, min(100, score))
    czy_warto = score >= 40

    tytul = przetarg_data.get("tytul", "przetarg")[:80]
    zamawiajacy = przetarg_data.get("zamawiajacy", "zamawiający")[:60]

    rekomendacja = (
        f'Romanie, znalazlam przetarg: "{tytul}" ({zamawiajacy}). '
        f"Oceniam go na {score}/100. "
    )
    if czy_warto:
        rekomendacja += "Wygląda interesująco — przygotowałam wstępny kosztorys, spojrzysz?"
    else:
        rekomendacja += "Mam pewne wątpliwości — " + "; ".join(uwagi[:2]) + ". Mimo to przygotowałam kosztorys gdybyś chciał ocenić."

    return OcenaPrzetargu(
        score=score,
        czy_warto=czy_warto,
        uzasadnienie="; ".join(uwagi) if uwagi else "Brak uwag szczególnych.",
        uwagi=uwagi,
        rekomendacja_emma=rekomendacja,
    )


async def ocen_przetarg(
    przetarg_data: dict,
    kontekst: dict,
) -> OcenaPrzetargu:
    """
    Główna funkcja oceny przetargu.

    przetarg_data: słownik z polami Przetarg (tytul, zamawiajacy, opis, wartosc, termin_skladania, cpv_kody)
    kontekst: dane o firmie — aktywne_budowy, etaty, nadchodzace_terminy itp.
    """
    system_prompt = """Jesteś asystentem firmy budowlanej Budkon.
Analizujesz przetargi budowlane i oceniasz czy firma powinna złożyć ofertę.
Odpowiadasz TYLKO w JSON z polami:
{
  "score": <0-100>,
  "czy_warto": <true/false>,
  "uzasadnienie": "<2-3 zdania>",
  "uwagi": ["<krótki alert>", ...],
  "rekomendacja_emma": "<wiadomość do Romana w stylu asystenta Emmy, po polsku, 2-3 zdania>"
}

W uwagach zwróć uwagę na:
- termin składania oferty (czy jest realny)
- wartość zamówienia vs typowe projekty firmy
- obciążenie firmy (aktywne budowy, etaty)
- czy zakres robót pasuje do profilu firmy (CPV kody)
- sezonowość / czas realizacji

Rekomendacja dla Emmy powinna być ciepła, bezpośrednia, jak od asystenta który dba o firmę.
Przykład: "Romanie, znalazłam przetarg na budynek biurowy w Krakowie — 850 tys. zł, termin do 15 stycznia.
Oceniam na 78/100, zakres pasuje do Waszego profilu. Przygotowałam kosztorys, spojrzysz?"
Jeśli mało mocy przerobowych, wspomnij o tym naturalnie.
"""

    user_prompt = f"""
Przetarg:
{json.dumps(przetarg_data, ensure_ascii=False, default=str, indent=2)}

Kontekst firmy:
{json.dumps(kontekst, ensure_ascii=False, default=str, indent=2)}
"""

    raw = await _call_llm(user_prompt, system_prompt)

    if raw:
        try:
            parsed = json.loads(raw)
            return OcenaPrzetargu(
                score=int(parsed.get("score", 50)),
                czy_warto=bool(parsed.get("czy_warto", True)),
                uzasadnienie=parsed.get("uzasadnienie", ""),
                uwagi=parsed.get("uwagi", []),
                rekomendacja_emma=parsed.get("rekomendacja_emma", ""),
            )
        except Exception as e:
            logger.warning("Błąd parsowania odpowiedzi LLM: %s", e)

    return _heurystyczna_ocena(przetarg_data, kontekst)


def _firma_kontekst(company_id: int) -> dict:
    """Pobiera kontekst firmy (aktywne budowy, etaty) z bazy."""
    try:
        from apps.budowa.models import Budowa

        aktywne = Budowa.objects.filter(
            company_id=company_id, status__in=["w_toku", "oferta"]
        ).count()
        return {
            "aktywne_budowy": aktywne,
            "company_id": company_id,
        }
    except Exception as e:
        logger.warning("Błąd pobierania kontekstu firmy: %s", e)
        return {"aktywne_budowy": 0, "company_id": company_id}


def ocen_przetarg_sync(przetarg_data: dict, company_id: int) -> OcenaPrzetargu:
    kontekst = _firma_kontekst(company_id)
    return asyncio.run(ocen_przetarg(przetarg_data, kontekst))
