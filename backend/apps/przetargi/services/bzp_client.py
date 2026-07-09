"""
Klient API BZP (Biuletyn Zamówień Publicznych) — ezamówienia.gov.pl
Dokumentacja: https://ezamowienia.gov.pl/mo-board/api/v1/docs
"""
import logging
from dataclasses import dataclass, field
from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional

import requests

logger = logging.getLogger(__name__)

BZP_BASE = "https://ezamowienia.gov.pl/mo-board/api/v1"

# CPV kody budowlane (poziom 45xxxxxxx = roboty budowlane)
CPV_BUDOWLANE_DEFAULT = [
    "45000000-7",  # roboty budowlane
    "45100000-8",  # przygotowanie terenu
    "45200000-9",  # roboty budowlane w zakresie wznoszenia kompletnych obiektów
    "45210000-2",  # roboty budowlane w zakresie budynków
    "45300000-0",  # roboty instalacyjne w budynkach
    "45400000-1",  # roboty wykończeniowe w zakresie obiektów budowlanych
    "45500000-2",  # wynajem maszyn i urządzeń wraz z obsługą operatorską
]


@dataclass
class BzpPrzetarg:
    bzp_id: str
    tytul: str
    zamawiajacy: str
    opis: str
    wartosc_szacunkowa: Optional[Decimal]
    waluta: str
    termin_skladania: Optional[datetime]
    termin_realizacji: Optional[str]
    lokalizacja: str
    cpv_kody: list[str]
    url: str
    raw: dict = field(default_factory=dict)


class BzpClient:
    def __init__(self, timeout: int = 30):
        self.session = requests.Session()
        self.session.headers.update({"Accept": "application/json"})
        self.timeout = timeout

    def szukaj(
        self,
        cpv_kody: list[str] | None = None,
        fraza: str | None = None,
        strona: int = 1,
        na_stronie: int = 50,
    ) -> tuple[list[BzpPrzetarg], int]:
        """
        Szuka przetargów w BZP.
        Zwraca (lista przetargów, łączna liczba wyników).
        """
        params: dict = {
            "pageSize": na_stronie,
            "pageNumber": strona,
            "status": "PUBLISHED",
        }

        if fraza:
            params["searchPhrase"] = fraza

        if cpv_kody:
            params["cpvCodes"] = ",".join(cpv_kody)

        try:
            resp = self.session.get(
                f"{BZP_BASE}/notices/search",
                params=params,
                timeout=self.timeout,
            )
            resp.raise_for_status()
        except requests.RequestException as e:
            logger.error("BZP API error: %s", e)
            raise

        data = resp.json()
        items = data.get("items", data.get("notices", []))
        total = data.get("totalCount", data.get("total", len(items)))

        return [self._parse(item) for item in items], total

    def pobierz_szczegoly(self, bzp_id: str) -> dict:
        try:
            resp = self.session.get(
                f"{BZP_BASE}/notices/{bzp_id}",
                timeout=self.timeout,
            )
            resp.raise_for_status()
            return resp.json()
        except requests.RequestException as e:
            logger.error("BZP detail error for %s: %s", bzp_id, e)
            raise

    def _parse(self, item: dict) -> BzpPrzetarg:
        wartosc = None
        if v := item.get("estimatedValue") or item.get("wartoscSzacunkowa"):
            try:
                wartosc = Decimal(str(v))
            except Exception:
                pass

        termin_skladania = None
        if ts := item.get("submissionDeadline") or item.get("terminSkladania"):
            try:
                termin_skladania = datetime.fromisoformat(
                    ts.replace("Z", "+00:00")
                )
            except Exception:
                pass

        cpv = []
        for cpv_field in ("cpvCodes", "cpvCode", "kodyKpv"):
            raw_cpv = item.get(cpv_field)
            if isinstance(raw_cpv, list):
                cpv = [
                    c if isinstance(c, str) else c.get("code", "")
                    for c in raw_cpv
                ]
                break
            elif isinstance(raw_cpv, str):
                cpv = [raw_cpv]
                break

        bzp_id = str(
            item.get("noticeId")
            or item.get("id")
            or item.get("numerOgłoszenia")
            or ""
        )

        url = (
            item.get("noticeUrl")
            or item.get("url")
            or f"https://ezamowienia.gov.pl/mo-board/notices/{bzp_id}"
        )

        return BzpPrzetarg(
            bzp_id=bzp_id,
            tytul=item.get("title") or item.get("tytul") or "",
            zamawiajacy=(
                item.get("buyer", {}).get("name")
                or item.get("zamawiajacy")
                or ""
            ),
            opis=item.get("description") or item.get("opis") or "",
            wartosc_szacunkowa=wartosc,
            waluta=item.get("currency") or item.get("waluta") or "PLN",
            termin_skladania=termin_skladania,
            termin_realizacji=item.get("completionDate") or item.get("terminRealizacji"),
            lokalizacja=(
                item.get("placeOfPerformance")
                or item.get("miejsce")
                or ""
            ),
            cpv_kody=cpv,
            url=url,
            raw=item,
        )
