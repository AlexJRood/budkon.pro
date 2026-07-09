import asyncio
import logging
from datetime import datetime, timezone

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import EmmaWiadomoscPrzetargu, FetchLog, Przetarg, SubskrypcjaPrzetargow
from .serializers import (
    EmmaWiadomoscSerializer,
    FetchLogSerializer,
    PrzetargDetailSerializer,
    PrzetargListSerializer,
    PrzetargWriteSerializer,
    SubskrypcjaSerializer,
)
from .services.fetcher import fetch_wszystkie
from .services.przetarg_ai import ocen_przetarg_sync

logger = logging.getLogger(__name__)


def _company_id(request) -> int:
    try:
        return int(request.headers.get("X-Company-Id", 1))
    except (TypeError, ValueError):
        return 1


class PrzetargViewSet(viewsets.ModelViewSet):
    """
    CRUD przetargów + akcje: fetch, analizuj, generuj_kosztorys, zmien_status.
    """

    def get_queryset(self):
        company_id = _company_id(self.request)
        qs = Przetarg.objects.filter(company_id=company_id)

        # Filtry z query params
        if s := self.request.query_params.get("status"):
            qs = qs.filter(status=s)
        if warto := self.request.query_params.get("czy_warto"):
            qs = qs.filter(ai_czy_warto=warto.lower() == "true")
        if q := self.request.query_params.get("q"):
            qs = qs.filter(tytul__icontains=q)

        return qs.order_by("-created_at")

    def get_serializer_class(self):
        if self.action in ("create", "update", "partial_update"):
            return PrzetargWriteSerializer
        if self.action == "retrieve":
            return PrzetargDetailSerializer
        return PrzetargListSerializer

    def perform_create(self, serializer):
        serializer.save(company_id=_company_id(self.request), zrodlo="manual")

    # ------------------------------------------------------------------ #
    # Akcje                                                                #
    # ------------------------------------------------------------------ #

    @action(detail=False, methods=["post"], url_path="fetch")
    def fetch(self, request):
        """Ręczne wyzwolenie pobierania przetargów z BZP."""
        company_id = _company_id(request)
        try:
            wyniki = fetch_wszystkie(company_id=company_id)
            total_new = sum(v["new"] for v in wyniki.values())
            return Response({"status": "ok", "nowych": total_new, "szczegoly": wyniki})
        except Exception as e:
            logger.error("Błąd fetch: %s", e)
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=["post"], url_path="analizuj")
    def analizuj(self, request, pk=None):
        """(Re)analizuje przetarg przez AI."""
        przetarg = self.get_object()
        przetarg_data = {
            "tytul": przetarg.tytul,
            "zamawiajacy": przetarg.zamawiajacy,
            "opis": przetarg.opis,
            "wartosc_szacunkowa": str(przetarg.wartosc_szacunkowa or ""),
            "termin_skladania": przetarg.termin_skladania.isoformat() if przetarg.termin_skladania else None,
            "cpv_kody": przetarg.cpv_kody,
            "lokalizacja": przetarg.lokalizacja,
        }
        try:
            ocena = ocen_przetarg_sync(przetarg_data, przetarg.company_id)
        except Exception as e:
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        przetarg.ai_score = ocena.score
        przetarg.ai_czy_warto = ocena.czy_warto
        przetarg.ai_uzasadnienie = ocena.uzasadnienie
        przetarg.ai_uwagi = ocena.uwagi
        przetarg.ai_analizowany_at = datetime.now(timezone.utc)
        if przetarg.status == "nowy":
            przetarg.status = "analizowany"
        przetarg.save()

        return Response(
            {
                "score": ocena.score,
                "czy_warto": ocena.czy_warto,
                "uzasadnienie": ocena.uzasadnienie,
                "uwagi": ocena.uwagi,
                "rekomendacja_emma": ocena.rekomendacja_emma,
            }
        )

    @action(detail=True, methods=["post"], url_path="generuj-kosztorys")
    def generuj_kosztorys(self, request, pk=None):
        """
        Generuje kosztorys dla przetargu przez AI.
        Tworzy nowy Kosztorys powiązany z przetargiem (bez budowy).
        """
        przetarg = self.get_object()

        try:
            from apps.kosztorysy.models import Kosztorys
            from apps.kosztorysy.pipeline import KosztorysAiPipeline

            kosztorys = Kosztorys.objects.create(
                company_id=przetarg.company_id,
                nazwa=f"Kosztorys do przetargu: {przetarg.tytul[:100]}",
                opis=f"Automatycznie wygenerowany dla: {przetarg.zamawiajacy}",
                status="roboczy",
            )

            pipeline = KosztorysAiPipeline()
            prompt = (
                f"Przetarg: {przetarg.tytul}\n"
                f"Zamawiający: {przetarg.zamawiajacy}\n"
                f"Opis: {przetarg.opis[:1000]}\n"
                f"Wartość szacunkowa: {przetarg.wartosc_szacunkowa} {przetarg.waluta}"
            )
            result = asyncio.run(
                pipeline.generate(
                    kosztorys_id=kosztorys.pk,
                    prompt=prompt,
                    powierzchnia_m2=None,
                    kubatura_m3=None,
                )
            )

            # Powiąż przetarg z kosztorysem
            przetarg.kosztorys_id = kosztorys.pk
            if przetarg.status in ("nowy", "analizowany"):
                przetarg.status = "kosztorys_gotowy"
            przetarg.save(update_fields=["kosztorys_id", "status"])

            return Response(
                {
                    "kosztorys_id": kosztorys.pk,
                    "status": "ok",
                    "pozycje": result.pozycje_count if hasattr(result, "pozycje_count") else None,
                },
                status=status.HTTP_201_CREATED,
            )
        except Exception as e:
            logger.error("Błąd generowania kosztorysu dla przetargu %d: %s", przetarg.pk, e)
            return Response(
                {"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=["patch"], url_path="status")
    def zmien_status(self, request, pk=None):
        """Zmiana statusu przetargu (zlozony, pominiety, wygrany...)."""
        przetarg = self.get_object()
        nowy_status = request.data.get("status")
        if nowy_status not in [s[0] for s in Przetarg._meta.get_field("status").choices]:
            return Response(
                {"error": "Nieprawidłowy status."}, status=status.HTTP_400_BAD_REQUEST
            )
        przetarg.status = nowy_status
        przetarg.save(update_fields=["status", "updated_at"])
        return Response({"status": nowy_status})


class SubskrypcjaViewSet(viewsets.ModelViewSet):
    serializer_class = SubskrypcjaSerializer

    def get_queryset(self):
        return SubskrypcjaPrzetargow.objects.filter(
            company_id=_company_id(self.request)
        )

    def perform_create(self, serializer):
        serializer.save(company_id=_company_id(self.request))


class EmmaWiadomosciViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Skrzynka proaktywnych wiadomości Emmy o przetargach.

    GET  /emma-inbox/          — wszystkie nieodrzucone
    GET  /emma-inbox/?tylko_nowe=1  — tylko nieprzeczytane
    POST /emma-inbox/{id}/przeczytaj/
    POST /emma-inbox/{id}/akceptuj/   — oznacza jako zaakceptowane
    POST /emma-inbox/{id}/odrzuc/     — oznacza jako odrzucone + ukrywa
    """

    serializer_class = EmmaWiadomoscSerializer

    def get_queryset(self):
        company_id = _company_id(self.request)
        qs = EmmaWiadomoscPrzetargu.objects.filter(
            company_id=company_id,
            zaakceptowana__isnull=True,  # nie odrzucone
        ).select_related("przetarg")

        if self.request.query_params.get("tylko_nowe") == "1":
            qs = qs.filter(przeczytana=False)

        return qs

    @action(detail=True, methods=["post"])
    def przeczytaj(self, request, pk=None):
        obj = self.get_object()
        obj.przeczytana = True
        obj.save(update_fields=["przeczytana"])
        return Response({"ok": True})

    @action(detail=True, methods=["post"])
    def akceptuj(self, request, pk=None):
        obj = self.get_object()
        obj.przeczytana = True
        obj.zaakceptowana = True
        obj.save(update_fields=["przeczytana", "zaakceptowana"])
        return Response({"ok": True, "przetarg_id": obj.przetarg_id})

    @action(detail=True, methods=["post"])
    def odrzuc(self, request, pk=None):
        obj = self.get_object()
        obj.przeczytana = True
        obj.zaakceptowana = False
        obj.save(update_fields=["przeczytana", "zaakceptowana"])
        return Response({"ok": True})


class FetchLogViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = FetchLogSerializer

    def get_queryset(self):
        return FetchLog.objects.filter(company_id=_company_id(self.request))[:100]
