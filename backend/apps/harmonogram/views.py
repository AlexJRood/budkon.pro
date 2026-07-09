import logging
from datetime import timedelta

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.budowa.models import Budowa, EtapBudowy
from .models import MilestoneHarmonogramu, ZadanieHarmonogramu
from .serializers import (
    EtapTimelineSerializer,
    MilestoneSerializer,
    ZadanieListSerializer,
    ZadanieWriteSerializer,
)

logger = logging.getLogger(__name__)


def _company_id(request) -> int:
    try:
        return int(request.headers.get("X-Company-Id", 1))
    except (TypeError, ValueError):
        return 1


class ZadanieViewSet(viewsets.ModelViewSet):
    """
    Zadania harmonogramu budowy.
    GET ?budowa=<id>           — wszystkie zadania budowy
    GET ?budowa=<id>&etap=<id> — zadania konkretnego etapu
    """

    def get_queryset(self):
        cid = _company_id(self.request)
        qs = ZadanieHarmonogramu.objects.filter(company_id=cid).select_related("etap")

        if budowa_id := self.request.query_params.get("budowa"):
            qs = qs.filter(budowa_id=budowa_id)
        if etap_id := self.request.query_params.get("etap"):
            qs = qs.filter(etap_id=etap_id)

        return qs.prefetch_related("poprzednicy")

    def get_serializer_class(self):
        if self.action in ("create", "update", "partial_update"):
            return ZadanieWriteSerializer
        return ZadanieListSerializer

    def perform_create(self, serializer):
        cid = _company_id(self.request)
        budowa_id = self.request.data.get("budowa_id")
        serializer.save(company_id=cid, budowa_id=budowa_id)

    @action(detail=True, methods=["patch"], url_path="postep")
    def aktualizuj_postep(self, request, pk=None):
        """PATCH /harmonogram/<id>/postep/ — {postep_procent: 0-100, status: ...}"""
        zadanie = self.get_object()
        postep = request.data.get("postep_procent")
        new_status = request.data.get("status")

        if postep is not None:
            zadanie.postep_procent = max(0, min(100, int(postep)))
        if new_status:
            zadanie.status = new_status
        if zadanie.postep_procent == 100 and not new_status:
            zadanie.status = "zakonczone"
        zadanie.save()

        return Response(ZadanieListSerializer(zadanie).data)


class MilestoneViewSet(viewsets.ModelViewSet):
    """Kamienie milowe budowy. GET ?budowa=<id>"""

    serializer_class = MilestoneSerializer

    def get_queryset(self):
        cid = _company_id(self.request)
        qs = MilestoneHarmonogramu.objects.filter(company_id=cid)
        if budowa_id := self.request.query_params.get("budowa"):
            qs = qs.filter(budowa_id=budowa_id)
        return qs

    def perform_create(self, serializer):
        cid = _company_id(self.request)
        budowa_id = self.request.data.get("budowa_id")
        serializer.save(company_id=cid, budowa_id=budowa_id)

    @action(detail=True, methods=["post"], url_path="osiagnij")
    def osiagnij(self, request, pk=None):
        ms = self.get_object()
        ms.osiagniety = True
        ms.save()
        return Response(MilestoneSerializer(ms).data)


class TimelineViewSet(viewsets.ViewSet):
    """
    Widok Gantta — etapy z zadaniami i milestones.
    GET /harmonogram/timeline/?budowa=<id>
    """

    def list(self, request):
        budowa_id = request.query_params.get("budowa")
        if not budowa_id:
            return Response({"error": "Wymagany ?budowa="}, status=400)

        cid = _company_id(request)

        try:
            budowa = Budowa.objects.get(pk=budowa_id, company_id=cid)
        except Budowa.DoesNotExist:
            return Response({"error": "Budowa nie znaleziona"}, status=404)

        etapy = (
            EtapBudowy.objects.filter(budowa=budowa)
            .prefetch_related(
                "zadania",
                "zadania__poprzednicy",
            )
            .order_by("kolejnosc")
        )

        milestones = MilestoneHarmonogramu.objects.filter(
            budowa=budowa, company_id=cid
        ).order_by("data")

        return Response({
            "budowa_id": budowa.pk,
            "budowa_nazwa": budowa.nazwa,
            "data_start": budowa.data_rozpoczecia,
            "data_koniec": budowa.data_planowanego_zakonczenia,
            "etapy": EtapTimelineSerializer(etapy, many=True).data,
            "milestones": MilestoneSerializer(milestones, many=True).data,
        })

    @action(detail=False, methods=["post"], url_path="auto-generuj")
    def auto_generuj(self, request):
        """
        Generuje domyślne zadania dla budowy na podstawie jej etapów.
        POST /harmonogram/timeline/auto-generuj/ {budowa_id: <id>}
        Przydatne na start — Roman dostaje gotowy szkielet harmonogramu.
        """
        cid = _company_id(request)
        budowa_id = request.data.get("budowa_id")
        if not budowa_id:
            return Response({"error": "Wymagany budowa_id"}, status=400)

        try:
            budowa = Budowa.objects.get(pk=budowa_id, company_id=cid)
        except Budowa.DoesNotExist:
            return Response({"error": "Budowa nie znaleziona"}, status=404)

        etapy = EtapBudowy.objects.filter(budowa=budowa).order_by("kolejnosc")
        created = 0

        for etap in etapy:
            # Pomiń jeśli etap ma już zadania
            if etap.zadania.exists():
                continue

            # Domyślne zadania dla etapu
            default_tasks = _default_tasks_for_etap(etap.typ or "")
            for i, (nazwa, dni) in enumerate(default_tasks):
                data_start = etap.data_start
                data_koniec = (
                    etap.data_start + timedelta(days=dni)
                    if etap.data_start
                    else None
                )
                ZadanieHarmonogramu.objects.create(
                    company_id=cid,
                    budowa=budowa,
                    etap=etap,
                    nazwa=nazwa,
                    kolejnosc=i,
                    czas_trwania_dni=dni,
                    data_start=data_start,
                    data_koniec=data_koniec,
                )
                created += 1

        return Response({"utworzono_zadan": created})


def _default_tasks_for_etap(typ: str) -> list[tuple[str, int]]:
    """Domyślne zadania (nazwa, czas_dni) dla każdego typu etapu."""
    defaults = {
        "projekt": [
            ("Projekt koncepcyjny", 14),
            ("Projekt budowlany", 21),
            ("Uzgodnienia", 14),
        ],
        "pozwolenie": [
            ("Złożenie wniosku PnB", 2),
            ("Oczekiwanie na decyzję", 65),
        ],
        "fundamenty": [
            ("Wytyczenie geodezyjne", 2),
            ("Wykop", 5),
            ("Ławy fundamentowe", 7),
            ("Izolacja fundamentów", 3),
            ("Zasypka i zagęszczenie", 2),
        ],
        "stan_surowy": [
            ("Ściany parteru", 14),
            ("Strop nad parterem", 7),
            ("Ściany piętra", 10),
            ("Wieńce i nadproża", 5),
        ],
        "dach": [
            ("Konstrukcja dachu", 10),
            ("Pokrycie dachu", 7),
            ("Obróbki blacharskie", 3),
            ("Okna dachowe", 2),
        ],
        "instalacje": [
            ("Instalacja elektryczna", 14),
            ("Instalacja wod-kan", 10),
            ("Instalacja CO", 10),
            ("Wentylacja / rekuperacja", 7),
        ],
        "wykonczenie": [
            ("Tynki wewnętrzne", 14),
            ("Wylewki", 7),
            ("Malowanie", 10),
            ("Podłogi", 7),
            ("Drzwi wewnętrzne", 3),
            ("Biały montaż", 3),
            ("Elewacja", 14),
        ],
        "odbiory": [
            ("Odbiór instalacji", 3),
            ("Odbiór budowlany", 2),
            ("Odbiór od inwestora", 1),
        ],
        "gwarancja": [
            ("Przegląd 6-miesięczny", 1),
            ("Przegląd roczny", 1),
        ],
    }
    return defaults.get(typ, [("Prace", 7)])
