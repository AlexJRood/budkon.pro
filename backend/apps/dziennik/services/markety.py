"""
Wyszukiwanie sklepów budowlanych w pobliżu budowy przez Overpass API.
Używa prywatnej instancji overpass.superbee.cloud.
"""
import logging
from dataclasses import dataclass

import requests

logger = logging.getLogger(__name__)

_OVERPASS_URL = "https://overpass.superbee.cloud/api/interpreter"

# Tagi OSM identyfikujące sklepy budowlane / materiały budowlane
_QUERY_TEMPLATE = """
[out:json][timeout:15];
(
  node["shop"="doityourself"](around:{radius},{lat},{lon});
  way["shop"="doityourself"](around:{radius},{lat},{lon});
  node["shop"="hardware"](around:{radius},{lat},{lon});
  way["shop"="hardware"](around:{radius},{lat},{lon});
  node["shop"="building_materials"](around:{radius},{lat},{lon});
  way["shop"="building_materials"](around:{radius},{lat},{lon});
  node["shop"="trade"]["trade"="construction"](around:{radius},{lat},{lon});
  way["shop"="trade"]["trade"="construction"](around:{radius},{lat},{lon});
);
out center tags;
"""

# Znane marki budowlane w Polsce
_ZNANE_MARKI = {
    "leroy merlin", "castorama", "obi", "bricomarché", "bricoman",
    "merkury market", "psb mrówka", "mrówka", "jula", "bauhaus",
    "hornbach", "praktiker", "bricomarche", "agrobex",
}


@dataclass
class MarketBudowlany:
    osm_id: str
    osm_type: str  # node / way
    nazwa: str
    adres: str
    lat: float
    lon: float
    dystans_m: float | None  # obliczany po stronie klienta lub None
    marka: str | None  # jeśli rozpoznana marka


def _extract_center(el: dict) -> tuple[float, float] | None:
    if el.get("type") == "node":
        return el.get("lat"), el.get("lon")
    center = el.get("center", {})
    lat = center.get("lat")
    lon = center.get("lon")
    if lat and lon:
        return lat, lon
    return None


def _buduj_adres(tags: dict) -> str:
    parts = []
    if ulica := tags.get("addr:street"):
        nr = tags.get("addr:housenumber", "")
        parts.append(f"{ulica} {nr}".strip())
    if miasto := tags.get("addr:city"):
        parts.append(miasto)
    return ", ".join(parts)


def _rozpoznaj_marke(nazwa: str) -> str | None:
    lower = nazwa.lower()
    for marka in _ZNANE_MARKI:
        if marka in lower:
            return marka.title()
    return None


def szukaj_marketow(
    lat: float,
    lon: float,
    radius_m: int = 15_000,
) -> list[MarketBudowlany]:
    """
    Zwraca listę sklepów budowlanych w promieniu `radius_m` metrów od punktu.
    Posortowane po nazwie (dystans oblicza Flutter przez lat/lon).
    """
    query = _QUERY_TEMPLATE.format(
        lat=round(lat, 6),
        lon=round(lon, 6),
        radius=radius_m,
    )

    try:
        resp = requests.post(
            _OVERPASS_URL,
            data={"data": query},
            timeout=20,
        )
        resp.raise_for_status()
        elements = resp.json().get("elements", [])
    except Exception as e:
        logger.error("Overpass błąd: %s", e)
        return []

    wyniki: list[MarketBudowlany] = []
    seen: set[str] = set()

    for el in elements:
        coords = _extract_center(el)
        if not coords or not all(coords):
            continue
        elat, elon = coords

        tags = el.get("tags", {})
        nazwa = (
            tags.get("name")
            or tags.get("brand")
            or tags.get("operator")
            or "Sklep budowlany"
        )

        # Deduplikacja po nazwie + przybliżonej lokalizacji
        key = f"{nazwa.lower()}:{round(elat, 3)}:{round(elon, 3)}"
        if key in seen:
            continue
        seen.add(key)

        wyniki.append(
            MarketBudowlany(
                osm_id=str(el.get("id", "")),
                osm_type=el.get("type", "node"),
                nazwa=nazwa,
                adres=_buduj_adres(tags),
                lat=elat,
                lon=elon,
                dystans_m=None,
                marka=_rozpoznaj_marke(nazwa),
            )
        )

    logger.info(
        "Overpass: znaleziono %d sklepów w promieniu %dm od (%.4f, %.4f)",
        len(wyniki), radius_m, lat, lon,
    )
    return wyniki
