"""
Geocoding adresu → lat/lon przez Nominatim (OpenStreetMap).
Bezpłatne, bez klucza API. Rate limit: 1 req/s.
"""
import logging
import time

import requests

logger = logging.getLogger(__name__)

_NOMINATIM_URL = "https://nominatim.superbee.cloud/search"
_HEADERS = {"User-Agent": "budkon.pro/1.0"}
_last_call = 0.0


def geocode(adres: str) -> tuple[float, float] | None:
    """
    Zwraca (lat, lon) dla podanego adresu lub None gdy geocoding się nie udał.
    Szanuje rate limit Nominatim (1 req/s).
    """
    global _last_call

    if not adres.strip():
        return None

    # Rate limit
    elapsed = time.monotonic() - _last_call
    if elapsed < 1.1:
        time.sleep(1.1 - elapsed)

    try:
        resp = requests.get(
            _NOMINATIM_URL,
            params={
                "q": adres,
                "format": "json",
                "limit": 1,
                "countrycodes": "pl",
            },
            headers=_HEADERS,
            timeout=10,
        )
        _last_call = time.monotonic()
        resp.raise_for_status()
        results = resp.json()
        if results:
            lat = float(results[0]["lat"])
            lon = float(results[0]["lon"])
            logger.info("Geocoding '%s' → (%.5f, %.5f)", adres, lat, lon)
            return lat, lon
    except Exception as e:
        logger.warning("Geocoding błąd dla '%s': %s", adres, e)

    return None


def geocode_budowa(budowa) -> bool:
    """
    Uzupełnia lat/lon na modelu Budowa jeśli ma adres i nie ma współrzędnych.
    Zapisuje do bazy. Zwraca True gdy sukces.
    """
    if budowa.lat and budowa.lon:
        return True

    if not budowa.adres:
        return False

    result = geocode(budowa.adres)
    if result:
        budowa.lat, budowa.lon = result
        budowa.save(update_fields=["lat", "lon"])
        return True

    return False
