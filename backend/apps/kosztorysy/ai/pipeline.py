"""
AI Kosztorys Pipeline
=====================
Input:  tekst opisu zakresu robót + optional obmiar dict
Output: lista działy → pozycje KNR z ilościami i cenami

Flow:
  1. LLM (Superbee) → identyfikuje rodzaje robót w JSON
  2. KNR wyszukiwanie po Django ORM (fulltext)
  3. Ceny z bazy Materialy → fallback tabela bazowych cen rynkowych
  4. Zwraca structured KosztorysDTO
"""

from __future__ import annotations
import json
import re
from dataclasses import dataclass, field
from decimal import Decimal
from typing import Optional
import httpx


# ── Tabela fallback cen bazowych (PLN/jm) ────────────────────────────────────
# Aktualizować raz na kwartał wg SEKOCENBUD / BCNORM
_CENY_BAZOWE: dict[str, Decimal] = {
    # robocizna
    "rbh": Decimal("28.00"),
    # ziemne
    "m3_ziemia": Decimal("45.00"),
    "m2_zasypka": Decimal("18.00"),
    # beton/żelbet
    "m3_beton": Decimal("650.00"),
    "m3_zelazobet": Decimal("820.00"),
    "m2_szalunek": Decimal("65.00"),
    # mury
    "m2_mur_pustak": Decimal("120.00"),
    "m2_mur_cegla": Decimal("150.00"),
    "m2_mur_silikat": Decimal("130.00"),
    # stropy / więźba
    "m2_strop_teriva": Decimal("210.00"),
    "m3_wiezba_dach": Decimal("280.00"),
    "m2_pokrycie_blacha": Decimal("95.00"),
    "m2_pokrycie_dachowka": Decimal("115.00"),
    # tynki
    "m2_tynk_gipsowy": Decimal("55.00"),
    "m2_tynk_cement": Decimal("48.00"),
    "m2_tynk_fasada": Decimal("85.00"),
    # wylewki / posadzki
    "m2_wylewka": Decimal("65.00"),
    "m2_plytki": Decimal("95.00"),
    "m2_parkiet": Decimal("120.00"),
    # okna / drzwi
    "szt_okno_pvc": Decimal("1_200.00"),
    "szt_drzwi_wewn": Decimal("800.00"),
    "szt_drzwi_zewn": Decimal("2_500.00"),
    # inst. wod-kan
    "mb_rura_pex": Decimal("22.00"),
    "szt_bateria": Decimal("350.00"),
    "kpl_laziebka": Decimal("4_500.00"),
    # inst. elektryczna
    "mb_przewod": Decimal("8.00"),
    "szt_gniazdo": Decimal("85.00"),
    "kpl_tablica": Decimal("1_200.00"),
    # ocieplenie
    "m2_styropian": Decimal("95.00"),
    "m2_welnawata": Decimal("85.00"),
    # malowanie
    "m2_malowanie": Decimal("25.00"),
    # default
    "default": Decimal("100.00"),
}


def _cena_dla_knr(knr_opis: str, jednostka: str) -> Decimal:
    """
    Heurystycznie dobiera cenę z tabeli bazowej na podstawie opisu i jm.
    Kolejność: dokładny klucz → słowo kluczowe w opisie → default.
    """
    opis_lower = (knr_opis + " " + jednostka).lower()
    reguły = [
        (["robocizna", "rbh"], "rbh"),
        (["beton", "żelbet", "żelbetowy"], "m3_zelazobet" if "zbrojony" in opis_lower else "m3_beton"),
        (["szalunek"], "m2_szalunek"),
        (["pustak", "bloczek"], "m2_mur_pustak"),
        (["cegła", "cegłą", "murowanie"], "m2_mur_cegla"),
        (["silikat"], "m2_mur_silikat"),
        (["teriva", "strop"], "m2_strop_teriva"),
        (["więźba", "dach", "krokiew"], "m3_wiezba_dach"),
        (["blacha", "blachę"], "m2_pokrycie_blacha"),
        (["dachówka", "dachówki"], "m2_pokrycie_dachowka"),
        (["tynk gips", "gipsowy"], "m2_tynk_gipsowy"),
        (["tynk cement", "cem-wap"], "m2_tynk_cement"),
        (["fasad", "elewacj"], "m2_tynk_fasada"),
        (["wylewka", "posadzka betonowa"], "m2_wylewka"),
        (["płytki", "glazura", "terakota"], "m2_plytki"),
        (["parkiet", "deska podłogowa"], "m2_parkiet"),
        (["okno", "okien"], "szt_okno_pvc"),
        (["drzwi wejściow", "drzwi zewn"], "szt_drzwi_zewn"),
        (["drzwi"], "szt_drzwi_wewn"),
        (["rura", "pex", "rur pp"], "mb_rura_pex"),
        (["bateria", "kran"], "szt_bateria"),
        (["łazienka", "wc", "sanitariaty"], "kpl_laziebka"),
        (["przewód", "kabel", "linia"], "mb_przewod"),
        (["gniazdo", "łącznik", "wyłącznik"], "szt_gniazdo"),
        (["tablica", "rozdzielnia"], "kpl_tablica"),
        (["styropian", "eps"], "m2_styropian"),
        (["wełna", "mineralna"], "m2_welnawata"),
        (["malow", "farba"], "m2_malowanie"),
        (["roboty ziemne", "wykop", "zasypka", "nasyp"], "m3_ziemia"),
    ]
    for słowa, klucz in reguły:
        if any(s in opis_lower for s in słowa):
            return _CENY_BAZOWE[klucz]
    return _CENY_BAZOWE["default"]


# ── DTO ────────────────────────────────────────────────────────────────────────

@dataclass
class PozycjaDTO:
    knr_pozycja_id: Optional[int]
    opis: str
    jednostka: str
    ilosc: Decimal
    cena_jednostkowa: Decimal
    ai_suggested_price: Optional[Decimal] = None
    ai_suggested_qty: Optional[Decimal] = None


@dataclass
class DzialDTO:
    nazwa: str
    pozycje: list[PozycjaDTO] = field(default_factory=list)


@dataclass
class KosztorysDTO:
    nazwa: str
    dzialy: list[DzialDTO] = field(default_factory=list)

    @property
    def suma(self) -> Decimal:
        return sum(p.ilosc * p.cena_jednostkowa for d in self.dzialy for p in d.pozycje)


# ── Pipeline ───────────────────────────────────────────────────────────────────

class KosztorysPipeline:
    """
    Orchestrates the full AI → KNR → prices → kosztorys flow.

    Usage:
        pipeline = KosztorysPipeline(superbee_url="http://192.168.1.109:8080")
        kosztorys = await pipeline.generate(
            opis="remont łazienki 8m2, wymiana płytek, instalacja, malowanie",
            obmiar={"powierzchnia_m2": 8},
            company_id=1,
        )
    """

    def __init__(self, superbee_url: str, superbee_token: str = ""):
        self.superbee_url = superbee_url
        self.superbee_token = superbee_token

    async def generate(
        self,
        opis: str,
        obmiar: dict | None = None,
        company_id: int = 0,
    ) -> KosztorysDTO:
        obmiar = obmiar or {}

        # Step 1: LLM identifies work types
        try:
            rodzaje_robot = await self._identify_work_types(opis, obmiar)
        except Exception as exc:
            # Graceful degradation — jeśli Superbee niedostępny, fallback na
            # heurystyczny parser (regex po słowach kluczowych)
            rodzaje_robot = self._heuristic_parse(opis, obmiar)

        # Step 2: Match KNR positions
        dzialy: list[DzialDTO] = []
        for rodzaj in rodzaje_robot:
            pozycje = await self._match_knr(rodzaj, obmiar, company_id)
            if pozycje:
                dzialy.append(DzialDTO(nazwa=rodzaj.get("nazwa", "Roboty"), pozycje=pozycje))

        # Jeśli KNR nic nie znalazł — utwórz pozycje własne z LLM data
        if not dzialy:
            dzialy = self._fallback_from_llm(rodzaje_robot, obmiar)

        return KosztorysDTO(nazwa=f"Kosztorys: {opis[:60]}", dzialy=dzialy)

    async def _identify_work_types(self, opis: str, obmiar: dict) -> list[dict]:
        """Call Superbee LLM to parse opis → list of work type dicts."""
        prompt = (
            "Jesteś ekspertem budownictwa w Polsce. Na podstawie opisu zakresu robót "
            "zwróć TYLKO listę JSON (bez komentarzy) rodzajów robót, każdy z polami:\n"
            "  - nazwa: string (np. 'Roboty ziemne')\n"
            "  - kategoria_knr: string (słowa kluczowe z katalogu KNR, np. 'wykop ziemia')\n"
            "  - szacowana_ilosc: number\n"
            "  - jednostka: string (m2/m3/mb/szt/kpl/rbh)\n\n"
            f"Opis: {opis}\n"
            f"Obmiar: {json.dumps(obmiar, ensure_ascii=False)}\n\n"
            "Odpowiedź (tylko JSON array):"
        )
        headers = {}
        if self.superbee_token:
            headers["Authorization"] = f"Bearer {self.superbee_token}"

        async with httpx.AsyncClient(timeout=45) as client:
            resp = await client.post(
                f"{self.superbee_url}/v1/chat",
                json={
                    "messages": [{"role": "user", "content": prompt}],
                    "json_mode": True,
                },
                headers=headers,
            )
            resp.raise_for_status()
            data = resp.json()
            # Superbee może zwrócić {"result": [...]} lub bezpośrednio listę
            raw = data.get("result", data.get("choices", [{}])[0].get("message", {}).get("content", data))
            if isinstance(raw, str):
                raw = json.loads(raw)
            if isinstance(raw, list):
                return raw
            return []

    def _heuristic_parse(self, opis: str, obmiar: dict) -> list[dict]:
        """
        Fallback gdy Superbee niedostępny.
        Regex dopasowuje polskie słowa kluczowe budownictwa.
        """
        pow = obmiar.get("powierzchnia_m2", 1)
        kub = obmiar.get("kubatura_m3", 1)
        rules = [
            (r"fund|wykop|ziemn|grunt|rob.ziem", "Roboty ziemne", "wykop ziemia nasyp", kub, "m3"),
            (r"beton|zelbet|żelbet|fundament|law|ław", "Roboty betonowe", "beton fundamenty zbrojenie", kub * 0.3, "m3"),
            (r"mur|scian|ścian|cegl|cegł|pustak|bloczek|silikat|murar", "Roboty murarskie", "mur sciana pustak", pow, "m2"),
            (r"strop|plyta|płyta", "Stropy", "strop teriva plyta", pow * 0.8, "m2"),
            (r"dach|wiezba|więźba|krokiew|pokryci|blacha|dachow", "Więźba i pokrycie", "dach wiezba pokrycie", pow, "m2"),
            (r"tynk|gladzenie|gładze", "Tynki", "tynk gipsowy", pow * 2.5, "m2"),
            (r"wylewk|posadzk|jastrych", "Wylewki", "wylewka posadzka", pow, "m2"),
            (r"plytki|płytki|glazur|terakot|okładzin|okladzin|kamien|kamień", "Okładziny", "plytki ceramiczne glazura", pow, "m2"),
            (r"okn|window", "Stolarka okienna", "okno pvc montaz", max(pow / 15, 1), "szt"),
            (r"drzwi|door", "Stolarka drzwiowa", "drzwi montaz", max(pow / 20, 1), "szt"),
            (r"wod-kan|wod\.kan|instalacj.*wod|kanalizacj|hydraul|pex|rur.*wod|woda|ciepla woda", "Inst. wod-kan", "rura pex instalacja woda", pow * 3, "mb"),
            (r"elektr|kabel|przewod|przewód|gniazdo|rozdzieln|instalacj.*el", "Inst. elektryczna", "kabel przewod elektryczny", pow * 4, "mb"),
            (r"ocieplen|styropian|welna|wełna|izolacj|termoizol", "Ocieplenie", "styropian ocieplenie", pow, "m2"),
            (r"malow|farba|gruntow|lazurje|bejca", "Malowanie", "malowanie farba", pow * 2.5, "m2"),
            (r"rusztow", "Rusztowania", "rusztowanie", pow / 4, "m2"),
        ]
        result = []
        for pattern, nazwa, kategoria, ilosc, jm in rules:
            if re.search(pattern, opis, re.IGNORECASE):
                result.append({
                    "nazwa": nazwa,
                    "kategoria_knr": kategoria,
                    "szacowana_ilosc": round(float(ilosc), 2),
                    "jednostka": jm,
                })
        if not result:
            result.append({
                "nazwa": "Roboty budowlane",
                "kategoria_knr": opis[:40],
                "szacowana_ilosc": 1,
                "jednostka": "kpl",
            })
        return result

    async def _match_knr(
        self, rodzaj: dict, obmiar: dict, company_id: int
    ) -> list[PozycjaDTO]:
        """Find KNR positions matching the work type."""
        from asgiref.sync import sync_to_async
        from ..models import KnrPozycja

        kategoria = rodzaj.get("kategoria_knr", "")
        słowa = [s for s in kategoria.split()[:4] if len(s) >= 3]

        @sync_to_async
        def fetch_knr():
            qs = KnrPozycja.objects.none()
            for słowo in słowa:
                qs = qs | KnrPozycja.objects.filter(opis__icontains=słowo)
            return list(qs.select_related("katalog").distinct()[:4])

        knr_list = await fetch_knr()

        ilosc = Decimal(str(rodzaj.get("szacowana_ilosc", 1)))
        pozycje = []
        for knr in knr_list:
            cena = await self._get_price(knr, company_id)
            pozycje.append(
                PozycjaDTO(
                    knr_pozycja_id=knr.pk,
                    opis=knr.opis,
                    jednostka=knr.jednostka,
                    ilosc=ilosc,
                    cena_jednostkowa=cena,
                    ai_suggested_price=cena,
                    ai_suggested_qty=ilosc,
                )
            )
        return pozycje

    async def _get_price(self, knr, company_id: int) -> Decimal:
        """
        Cena: najpierw sprawdź bazę materiałów (apps.materialy),
        fallback → tabela bazowych cen rynkowych.
        """
        try:
            from asgiref.sync import sync_to_async
            from apps.materialy.models import Material

            @sync_to_async
            def fetch_mat():
                return Material.objects.filter(
                    company_id=company_id,
                    nazwa__icontains=knr.opis.split()[0],
                ).first()

            mat = await fetch_mat()
            if mat and getattr(mat, "cena_jednostkowa", None):
                return Decimal(str(mat.cena_jednostkowa))
        except Exception:
            pass
        return _cena_dla_knr(knr.opis, knr.jednostka)

    def _fallback_from_llm(
        self, rodzaje: list[dict], obmiar: dict
    ) -> list[DzialDTO]:
        """
        Gdy KNR nic nie znalazł — utwórz pozycje własne (nieskatalogowane)
        bezpośrednio z danych LLM + tabela cen.
        """
        dzialy = []
        for rodzaj in rodzaje:
            ilosc = Decimal(str(rodzaj.get("szacowana_ilosc", 1)))
            jm = rodzaj.get("jednostka", "kpl")
            opis = rodzaj.get("nazwa", "Roboty")
            cena = _cena_dla_knr(opis, jm)
            dzialy.append(DzialDTO(
                nazwa=opis,
                pozycje=[PozycjaDTO(
                    knr_pozycja_id=None,
                    opis=opis,
                    jednostka=jm,
                    ilosc=ilosc,
                    cena_jednostkowa=cena,
                    ai_suggested_price=cena,
                    ai_suggested_qty=ilosc,
                )],
            ))
        return dzialy
