"""
Parser plików ATH2 (XML) z NormaPro.
=====================================
Import jednorazowy starych kosztorysów taty → seed danych + AI few-shot examples.

Format ATH2 to XML z elementami:
  <Kosztorys> → <Dzial> → <Pozycja> z atrybutami knr, opis, jm, ilosc, cena

Usage:
    parser = Ath2Parser()
    kosztorys_dto = parser.parse(Path("remont_lazienki.ath"))
    parser.save_to_db(kosztorys_dto, company_id=1, created_by=1)
"""

from __future__ import annotations
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Optional


@dataclass
class Ath2Pozycja:
    knr_ref: str  # np. "KNR 2-02 0201-01"
    opis: str
    jednostka: str
    ilosc: Decimal
    cena_r: Decimal  # robocizna
    cena_m: Decimal  # materiały
    cena_s: Decimal  # sprzęt


@dataclass
class Ath2Dzial:
    nazwa: str
    pozycje: list[Ath2Pozycja] = field(default_factory=list)


@dataclass
class Ath2Kosztorys:
    nazwa: str
    obiekt: str
    dzialy: list[Ath2Dzial] = field(default_factory=list)

    @property
    def suma(self) -> Decimal:
        return sum(
            p.ilosc * (p.cena_r + p.cena_m + p.cena_s)
            for d in self.dzialy
            for p in d.pozycje
        )


class Ath2Parser:
    """Parse NormaPro ATH/ATH2 XML export files."""

    def parse(self, path: Path) -> Ath2Kosztorys:
        tree = ET.parse(path)
        root = tree.getroot()

        # ATH2 XML structure varies by NormaPro version; handle both
        # common root tags: <Kosztorys>, <ATH2>, <Norma>
        kosztorys_node = (
            root if root.tag in ("Kosztorys", "ATH2") else root.find("Kosztorys")
        )
        if kosztorys_node is None:
            kosztorys_node = root

        nazwa = kosztorys_node.get("Nazwa", "") or self._text(
            kosztorys_node, "Nazwa", "Kosztorys"
        )
        obiekt = kosztorys_node.get("Obiekt", "") or self._text(
            kosztorys_node, "Obiekt", ""
        )

        dzialy = []
        for dzial_node in kosztorys_node.iter("Dzial"):
            dzial = self._parse_dzial(dzial_node)
            if dzial.pozycje:
                dzialy.append(dzial)

        return Ath2Kosztorys(nazwa=nazwa, obiekt=obiekt, dzialy=dzialy)

    def _parse_dzial(self, node: ET.Element) -> Ath2Dzial:
        nazwa = node.get("Nazwa", "") or self._text(node, "Nazwa", "Dział")
        pozycje = [self._parse_pozycja(p) for p in node.iter("Pozycja")]
        return Ath2Dzial(nazwa=nazwa, pozycje=[p for p in pozycje if p])

    def _parse_pozycja(self, node: ET.Element) -> Optional[Ath2Pozycja]:
        try:
            knr_ref = node.get("KNR", "") or self._text(node, "KNR", "")
            opis = node.get("Opis", "") or self._text(node, "Opis", "")
            jm = node.get("JM", "") or self._text(node, "JM", "szt")
            ilosc = self._dec(node.get("Ilosc") or self._text(node, "Ilosc", "1"))
            cena_r = self._dec(node.get("CenaR") or self._text(node, "CenaR", "0"))
            cena_m = self._dec(node.get("CenaM") or self._text(node, "CenaM", "0"))
            cena_s = self._dec(node.get("CenaS") or self._text(node, "CenaS", "0"))
            return Ath2Pozycja(
                knr_ref=knr_ref,
                opis=opis,
                jednostka=jm,
                ilosc=ilosc,
                cena_r=cena_r,
                cena_m=cena_m,
                cena_s=cena_s,
            )
        except Exception:
            return None

    def save_to_db(
        self, kosztorys: Ath2Kosztorys, company_id: int, created_by: int
    ) -> int:
        """Persist parsed kosztorys to Django models. Returns Kosztorys.pk."""
        from ..models import Kosztorys, KosztorysdzDzial, KosztorysPozycja, KnrPozycja

        db_k = Kosztorys.objects.create(
            company_id=company_id,
            nazwa=kosztorys.nazwa,
            opis=kosztorys.obiekt,
            status="zatwierdzony",
            ai_prompt="[import NormaPro ATH2]",
            created_by=created_by,
        )
        for i, dzial in enumerate(kosztorys.dzialy):
            db_d = KosztorysdzDzial.objects.create(
                kosztorys=db_k, nazwa=dzial.nazwa, kolejnosc=i
            )
            for j, poz in enumerate(dzial.pozycje):
                knr = (
                    KnrPozycja.objects.filter(
                        numer__icontains=poz.knr_ref.split()[-1]
                    ).first()
                    if poz.knr_ref
                    else None
                )

                KosztorysPozycja.objects.create(
                    dzial=db_d,
                    knr_pozycja=knr,
                    opis=poz.opis,
                    jednostka=poz.jednostka,
                    ilosc=poz.ilosc,
                    cena_jednostkowa=poz.cena_r + poz.cena_m + poz.cena_s,
                    kolejnosc=j,
                )
        return db_k.pk

    @staticmethod
    def _text(node: ET.Element, tag: str, default: str) -> str:
        child = node.find(tag)
        return (child.text or "").strip() if child is not None else default

    @staticmethod
    def _dec(value: str) -> Decimal:
        try:
            return Decimal(value.replace(",", ".").strip())
        except (InvalidOperation, AttributeError):
            return Decimal("0")
