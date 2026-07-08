"""
AI Kosztorys Pipeline
=====================
Input:  tekst opisu zakresu robót + optional obmiar dict
Output: lista działy → pozycje KNR z ilościami i cenami

Flow:
  1. LLM (Superbee) → identyfikuje rodzaje robót
  2. KNR wyszukiwanie po Django ORM (fulltext lub vector)
  3. Ceny z bazy Materialy + polsearch live fallback
  4. Zwraca structured KosztorysDTO
"""

from __future__ import annotations
from dataclasses import dataclass, field
from decimal import Decimal
from typing import Optional
import httpx


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


class KosztorysPipeline:
    """
    Orchestrates the full AI → KNR → prices → kosztorys flow.

    Usage:
        pipeline = KosztorysPipeline(superbee_url="http://superbee.cloud:8080")
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
        # Step 1: LLM identifies work types
        rodzaje_robot = await self._identify_work_types(opis, obmiar or {})

        # Step 2: Match KNR positions
        dzialy: list[DzialDTO] = []
        for rodzaj in rodzaje_robot:
            pozycje = await self._match_knr(rodzaj, obmiar or {})
            if pozycje:
                dzialy.append(DzialDTO(nazwa=rodzaj["nazwa"], pozycje=pozycje))

        return KosztorysDTO(nazwa=f"Kosztorys: {opis[:60]}", dzialy=dzialy)

    async def _identify_work_types(self, opis: str, obmiar: dict) -> list[dict]:
        """Call Superbee LLM to parse opis → list of work type dicts."""
        prompt = (
            "Jesteś ekspertem budownictwa. Na podstawie opisu zakresu robót "
            "zwróć listę JSON rodzajów robót z polami: nazwa, kategoria_knr, "
            f"szacowana_ilosc, jednostka.\n\nOpis: {opis}\nObmiar: {obmiar}"
        )
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                f"{self.superbee_url}/v1/chat",
                json={
                    "messages": [{"role": "user", "content": prompt}],
                    "json_mode": True,
                },
                headers={"Authorization": f"Bearer {self.superbee_token}"},
            )
            resp.raise_for_status()
            data = resp.json()
            return data.get("result", [])

    async def _match_knr(self, rodzaj: dict, obmiar: dict) -> list[PozycjaDTO]:
        """Find KNR positions matching the work type."""
        from ..models import KnrPozycja  # lazy import to avoid circular

        kategoria = rodzaj.get("kategoria_knr", "")
        qs = KnrPozycja.objects.filter(opis__icontains=kategoria)[:5]

        pozycje = []
        for knr in qs:
            ilosc = Decimal(str(rodzaj.get("szacowana_ilosc", 1)))
            cena = await self._get_price(knr, company_id=0)
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
        """Get price from materials DB; fallback to polsearch live search."""
        # TODO: query materialy app for current price
        # TODO: polsearch live fallback
        return Decimal("100.00")  # placeholder
