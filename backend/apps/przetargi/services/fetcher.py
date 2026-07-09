"""
Pobieranie przetargów z BZP dla wszystkich aktywnych subskrypcji.
Wywoływane z management command lub Celery beat.
"""
import logging
from datetime import datetime, timezone

from django.db import transaction

from apps.przetargi.models import (
    FetchLog,
    Przetarg,
    SubskrypcjaPrzetargow,
    ZrodloPrzetargu,
)
from apps.przetargi.services.bzp_client import BzpClient, CPV_BUDOWLANE_DEFAULT
from apps.przetargi.services.przetarg_ai import ocen_przetarg_sync

logger = logging.getLogger(__name__)


def _przetarg_from_bzp(bzp, company_id: int) -> dict:
    return {
        "company_id": company_id,
        "tytul": bzp.tytul[:500],
        "zamawiajacy": bzp.zamawiajacy[:300],
        "opis": bzp.opis,
        "wartosc_szacunkowa": bzp.wartosc_szacunkowa,
        "waluta": bzp.waluta,
        "termin_skladania": bzp.termin_skladania,
        "termin_realizacji": bzp.termin_realizacji or None,
        "lokalizacja": bzp.lokalizacja[:200],
        "cpv_kody": bzp.cpv_kody,
        "zrodlo": ZrodloPrzetargu.BZP,
        "zrodlo_id": bzp.bzp_id,
        "zrodlo_url": bzp.url,
        "raw_data": bzp.raw,
    }


def fetch_dla_subskrypcji(sub: SubskrypcjaPrzetargow) -> tuple[int, int]:
    """
    Pobiera przetargi dla jednej subskrypcji.
    Zwraca (count_fetched, count_new).
    """
    client = BzpClient()
    cpv = sub.cpv_kody or CPV_BUDOWLANE_DEFAULT
    fraza = " ".join(sub.slowa_kluczowe) if sub.slowa_kluczowe else None

    log = FetchLog.objects.create(
        zrodlo=ZrodloPrzetargu.BZP,
        company_id=sub.company_id,
    )

    count_fetched = 0
    count_new = 0

    try:
        przetargi, total = client.szukaj(cpv_kody=cpv, fraza=fraza, na_stronie=50)
        count_fetched = len(przetargi)

        for bzp in przetargi:
            if not bzp.bzp_id:
                continue

            dane = _przetarg_from_bzp(bzp, sub.company_id)

            obj, created = Przetarg.objects.get_or_create(
                zrodlo=ZrodloPrzetargu.BZP,
                zrodlo_id=bzp.bzp_id,
                company_id=sub.company_id,
                defaults=dane,
            )

            if created:
                count_new += 1
                _analizuj_asynchronicznie(obj)

    except Exception as e:
        logger.error("Błąd fetch dla subskrypcji %d: %s", sub.pk, e)
        log.blad = str(e)

    log.finished_at = datetime.now(timezone.utc)
    log.count_fetched = count_fetched
    log.count_new = count_new
    log.save()

    SubskrypcjaPrzetargow.objects.filter(pk=sub.pk).update(
        ostatnie_pobranie=datetime.now(timezone.utc)
    )

    return count_fetched, count_new


def _analizuj_asynchronicznie(przetarg: Przetarg):
    """Uruchamia AI ocenę. W produkcji zastąpić Celery task."""
    try:
        przetarg_data = {
            "tytul": przetarg.tytul,
            "zamawiajacy": przetarg.zamawiajacy,
            "opis": przetarg.opis,
            "wartosc_szacunkowa": str(przetarg.wartosc_szacunkowa or ""),
            "termin_skladania": przetarg.termin_skladania.isoformat() if przetarg.termin_skladania else None,
            "cpv_kody": przetarg.cpv_kody,
            "lokalizacja": przetarg.lokalizacja,
        }
        ocena = ocen_przetarg_sync(przetarg_data, przetarg.company_id)

        Przetarg.objects.filter(pk=przetarg.pk).update(
            ai_score=ocena.score,
            ai_czy_warto=ocena.czy_warto,
            ai_uzasadnienie=ocena.uzasadnienie,
            ai_uwagi=ocena.uwagi,
            ai_analizowany_at=datetime.now(timezone.utc),
            status="analizowany",
        )
    except Exception as e:
        logger.error("Błąd AI analizy przetargu %d: %s", przetarg.pk, e)


def fetch_wszystkie(company_id: int | None = None) -> dict:
    """Pobiera przetargi dla wszystkich (lub jednej) aktywnych subskrypcji."""
    qs = SubskrypcjaPrzetargow.objects.filter(aktywna=True)
    if company_id:
        qs = qs.filter(company_id=company_id)

    wyniki = {}
    for sub in qs:
        fetched, new = fetch_dla_subskrypcji(sub)
        wyniki[sub.pk] = {"fetched": fetched, "new": new}
        logger.info(
            "Sub %d (firma %d): pobrano %d, nowych %d",
            sub.pk, sub.company_id, fetched, new,
        )

    return wyniki
