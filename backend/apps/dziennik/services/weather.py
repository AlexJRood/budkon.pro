"""
Pobieranie aktualnej pogody przez Open-Meteo API.
Bezpłatne, bez klucza API.
https://open-meteo.com/en/docs
"""
import logging
from dataclasses import dataclass
from datetime import date
from typing import Optional

import requests

from apps.dziennik.models import PogodaTyp

logger = logging.getLogger(__name__)

_BASE = "https://api.open-meteo.com/v1/forecast"

# WMO Weather Code → PogodaTyp
# https://open-meteo.com/en/docs#weathervariables
_WMO_MAP: dict[int, str] = {
    0: PogodaTyp.SLONECZNIE,
    1: PogodaTyp.SLONECZNIE,
    2: PogodaTyp.CZESCIOWE_ZACHMURZENIE,
    3: PogodaTyp.POCHMURNO,
    45: PogodaTyp.MGLA,
    48: PogodaTyp.MGLA,
    51: PogodaTyp.DESZCZ,
    53: PogodaTyp.DESZCZ,
    55: PogodaTyp.DESZCZ,
    61: PogodaTyp.DESZCZ,
    63: PogodaTyp.DESZCZ,
    65: PogodaTyp.DESZCZ,
    71: PogodaTyp.SNIEG,
    73: PogodaTyp.SNIEG,
    75: PogodaTyp.SNIEG,
    77: PogodaTyp.SNIEG,
    80: PogodaTyp.DESZCZ,
    81: PogodaTyp.DESZCZ,
    82: PogodaTyp.DESZCZ,
    85: PogodaTyp.SNIEG,
    86: PogodaTyp.SNIEG,
    95: PogodaTyp.BURZA,
    96: PogodaTyp.BURZA,
    99: PogodaTyp.BURZA,
}


@dataclass
class PogodaSnapshot:
    pogoda: str          # PogodaTyp value
    temperatura: float   # °C
    predkosc_wiatru: float  # km/h
    opady: float         # mm (last hour)
    wmo_code: int


def pobierz_pogode(lat: float, lon: float) -> Optional[PogodaSnapshot]:
    """
    Pobiera bieżącą pogodę dla podanych współrzędnych.
    Używa Open-Meteo current weather endpoint.
    """
    try:
        resp = requests.get(
            _BASE,
            params={
                "latitude": round(lat, 4),
                "longitude": round(lon, 4),
                "current": "temperature_2m,windspeed_10m,precipitation,weathercode",
                "wind_speed_unit": "kmh",
                "timezone": "Europe/Warsaw",
            },
            timeout=10,
        )
        resp.raise_for_status()
        data = resp.json()
        cur = data.get("current", {})

        wmo = int(cur.get("weathercode", 0))
        temp = float(cur.get("temperature_2m", 0))
        wiatr = float(cur.get("windspeed_10m", 0))
        opady = float(cur.get("precipitation", 0))

        # Silny wiatr nadpisuje typ pogody
        pogoda = _WMO_MAP.get(wmo, PogodaTyp.POCHMURNO)
        if wiatr >= 40 and pogoda not in (PogodaTyp.BURZA,):
            pogoda = PogodaTyp.WIATR

        # Mróz (temp < -5 bez opadów)
        if temp <= -5 and opady == 0:
            pogoda = PogodaTyp.MRÓZ

        logger.info(
            "Pogoda (%.4f, %.4f): %s %.1f°C wiatr %.0f km/h",
            lat, lon, pogoda, temp, wiatr,
        )
        return PogodaSnapshot(
            pogoda=pogoda,
            temperatura=temp,
            predkosc_wiatru=wiatr,
            opady=opady,
            wmo_code=wmo,
        )
    except Exception as e:
        logger.warning("Open-Meteo błąd: %s", e)
        return None


def pobierz_pogode_historyczna(
    lat: float, lon: float, data: date
) -> Optional[PogodaSnapshot]:
    """
    Pobiera średnią pogodę dla konkretnego dnia (historical API).
    Używane gdy wpis jest tworzony z opóźnieniem.
    """
    try:
        resp = requests.get(
            "https://archive-api.open-meteo.com/v1/archive",
            params={
                "latitude": round(lat, 4),
                "longitude": round(lon, 4),
                "start_date": data.isoformat(),
                "end_date": data.isoformat(),
                "daily": "temperature_2m_mean,windspeed_10m_max,precipitation_sum,weathercode",
                "timezone": "Europe/Warsaw",
            },
            timeout=10,
        )
        resp.raise_for_status()
        d = resp.json().get("daily", {})

        wmo = int((d.get("weathercode") or [0])[0])
        temp = float((d.get("temperature_2m_mean") or [0])[0] or 0)
        wiatr = float((d.get("windspeed_10m_max") or [0])[0] or 0)
        opady = float((d.get("precipitation_sum") or [0])[0] or 0)

        pogoda = _WMO_MAP.get(wmo, PogodaTyp.POCHMURNO)
        if wiatr >= 40 and pogoda != PogodaTyp.BURZA:
            pogoda = PogodaTyp.WIATR
        if temp <= -5 and opady == 0:
            pogoda = PogodaTyp.MRÓZ

        return PogodaSnapshot(
            pogoda=pogoda,
            temperatura=temp,
            predkosc_wiatru=wiatr,
            opady=opady,
            wmo_code=wmo,
        )
    except Exception as e:
        logger.warning("Open-Meteo historical błąd dla %s: %s", data, e)
        return None


def auto_uzupelnij_pogode(wpis) -> bool:
    """
    Uzupełnia pogodę na wpisie dziennika.
    Wybiera API bieżące lub historyczne w zależności od daty.
    Zwraca True gdy dane zostały pobrane.
    """
    from datetime import date as date_cls

    budowa = wpis.budowa
    if not (budowa.lat and budowa.lon):
        from apps.dziennik.services.geocoding import geocode_budowa
        if not geocode_budowa(budowa):
            logger.info(
                "Brak współrzędnych dla budowy %d — pomijam pogodę", budowa.pk
            )
            return False

    dzisiaj = date_cls.today()
    if wpis.data == dzisiaj:
        snap = pobierz_pogode(budowa.lat, budowa.lon)
    else:
        snap = pobierz_pogode_historyczna(budowa.lat, budowa.lon, wpis.data)

    if snap is None:
        return False

    wpis.pogoda = snap.pogoda
    wpis.temperatura = snap.temperatura
    wpis.predkosc_wiatru = snap.predkosc_wiatru
    wpis.opady = snap.opady
    wpis.pogoda_auto = True
    wpis.save(update_fields=[
        "pogoda", "temperatura", "predkosc_wiatru", "opady", "pogoda_auto"
    ])
    return True
