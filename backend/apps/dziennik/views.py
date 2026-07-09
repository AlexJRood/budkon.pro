import logging
from datetime import date

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

from .models import ObecnoscNaBudowie, WpisDziennika, ZdjecieDziennika
from .serializers import (
    WpisDetailSerializer,
    WpisListSerializer,
    WpisWriteSerializer,
    ZdjecieSerializer,
)
from .services.geocoding import geocode_budowa
from .services.markety import szukaj_marketow
from .services.weather import auto_uzupelnij_pogode, pobierz_pogode, pobierz_pogode_historyczna

logger = logging.getLogger(__name__)


def _company_id(request) -> int:
    try:
        return int(request.headers.get("X-Company-Id", 1))
    except (TypeError, ValueError):
        return 1


class WpisDziennikViewSet(viewsets.ModelViewSet):
    """
    Dziennik budowy — CRUD wpisów + auto-uzupełnianie pogody i etapu.

    Filtry query params:
      ?budowa=<id>   — wpisy dla konkretnej budowy (wymagane)
      ?rok=2025&miesiac=6  — filtr po miesiącu
    """

    def get_queryset(self):
        company_id = _company_id(self.request)
        qs = WpisDziennika.objects.filter(company_id=company_id)

        if budowa_id := self.request.query_params.get("budowa"):
            qs = qs.filter(budowa_id=budowa_id)
        if rok := self.request.query_params.get("rok"):
            qs = qs.filter(data__year=rok)
        if miesiac := self.request.query_params.get("miesiac"):
            qs = qs.filter(data__month=miesiac)

        return qs.select_related("etap").prefetch_related("zdjecia")

    def get_serializer_class(self):
        if self.action in ("create", "update", "partial_update"):
            return WpisWriteSerializer
        if self.action == "retrieve":
            return WpisDetailSerializer
        return WpisListSerializer

    def perform_create(self, serializer):
        company_id = _company_id(self.request)
        wpis = serializer.save(
            company_id=company_id,
            autor_id=self.request.user.pk if self.request.user.is_authenticated else None,
        )
        # Auto-uzupełnij pogodę w tle jeśli jej brak
        if not wpis.pogoda:
            try:
                auto_uzupelnij_pogode(wpis)
            except Exception as e:
                logger.warning("Auto-pogoda błąd dla wpisu %d: %s", wpis.pk, e)

    # ------------------------------------------------------------------ #
    # Akcje                                                                #
    # ------------------------------------------------------------------ #

    @action(detail=False, methods=["get"], url_path="auto-uzupelnij")
    def auto_uzupelnij(self, request):
        """
        Zwraca sugerowane wartości dla nowego wpisu (bez tworzenia go).
        Używane przez Flutter przed otwarciem formularza.

        Query params: ?budowa=<id>&data=YYYY-MM-DD (opcjonalny, default: dzisiaj)
        """
        budowa_id = request.query_params.get("budowa")
        if not budowa_id:
            return Response(
                {"error": "Wymagany parametr ?budowa=<id>"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            from apps.budowa.models import Budowa, EtapBudowy
            budowa = Budowa.objects.get(
                pk=budowa_id, company_id=_company_id(request)
            )
        except Exception:
            return Response({"error": "Budowa nie znaleziona"}, status=404)

        # Data wpisu
        data_str = request.query_params.get("data")
        try:
            wpis_data = date.fromisoformat(data_str) if data_str else date.today()
        except ValueError:
            wpis_data = date.today()

        # Geocoding jeśli brak współrzędnych
        geocode_budowa(budowa)

        # Pogoda
        pogoda_data = {}
        if budowa.lat and budowa.lon:
            snap = (
                pobierz_pogode(budowa.lat, budowa.lon)
                if wpis_data == date.today()
                else pobierz_pogode_historyczna(budowa.lat, budowa.lon, wpis_data)
            )
            if snap:
                pogoda_data = {
                    "pogoda": snap.pogoda,
                    "temperatura": snap.temperatura,
                    "predkosc_wiatru": snap.predkosc_wiatru,
                    "opady": snap.opady,
                }

        # Aktywny etap
        aktywny_etap = None
        try:
            from apps.budowa.models import EtapBudowy
            aktywny_etap = (
                EtapBudowy.objects.filter(
                    budowa=budowa,
                    status="w_toku",
                )
                .order_by("kolejnosc")
                .first()
            )
            if not aktywny_etap:
                # Fallback: etap który powinien być aktywny po dacie
                aktywny_etap = (
                    EtapBudowy.objects.filter(
                        budowa=budowa,
                        data_start__lte=wpis_data,
                    )
                    .exclude(status="zakończony")
                    .order_by("-data_start")
                    .first()
                )
        except Exception:
            pass

        # Liczba pracowników z poprzedniego wpisu (podpowiedź)
        poprzedni_wpis = (
            WpisDziennika.objects.filter(budowa=budowa, data__lt=wpis_data)
            .order_by("-data")
            .first()
        )

        return Response({
            **pogoda_data,
            "data": wpis_data.isoformat(),
            "etap_id": aktywny_etap.pk if aktywny_etap else None,
            "etap_nazwa": aktywny_etap.nazwa if aktywny_etap else None,
            "liczba_pracownikow_poprzedni": (
                poprzedni_wpis.liczba_pracownikow if poprzedni_wpis else 0
            ),
            "obecnosci_poprzednie": list(
                poprzedni_wpis.obecnosci.values(
                    "contact_id", "imie_nazwisko", "rola", "godziny"
                )
            ) if poprzedni_wpis else [],
        })

    @action(
        detail=True,
        methods=["post"],
        url_path="dodaj-zdjecie",
        parser_classes=[MultiPartParser, FormParser],
    )
    def dodaj_zdjecie(self, request, pk=None):
        """Upload zdjęcia do wpisu dziennika."""
        wpis = self.get_object()
        plik = request.FILES.get("plik")
        if not plik:
            return Response(
                {"error": "Brak pliku"}, status=status.HTTP_400_BAD_REQUEST
            )

        zdjecie = ZdjecieDziennika.objects.create(
            wpis=wpis,
            plik=plik,
            opis=request.data.get("opis", ""),
        )
        return Response(
            ZdjecieSerializer(zdjecie, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["delete"], url_path="zdjecia/(?P<zdjecie_pk>[^/.]+)")
    def usun_zdjecie(self, request, pk=None, zdjecie_pk=None):
        wpis = self.get_object()
        try:
            z = ZdjecieDziennika.objects.get(pk=zdjecie_pk, wpis=wpis)
            z.plik.delete(save=False)
            z.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except ZdjecieDziennika.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

    @action(detail=False, methods=["get"], url_path="markety-budowlane")
    def markety_budowlane(self, request):
        """
        Sklepy budowlane w pobliżu budowy.
        GET /dziennik/markety-budowlane/?budowa=<id>&radius=15000
        """
        budowa_id = request.query_params.get("budowa")
        if not budowa_id:
            return Response({"error": "Wymagany ?budowa="}, status=400)

        try:
            radius = int(request.query_params.get("radius", 15_000))
            radius = min(radius, 50_000)  # max 50 km
        except ValueError:
            radius = 15_000

        try:
            from apps.budowa.models import Budowa
            budowa = Budowa.objects.get(
                pk=budowa_id, company_id=_company_id(request)
            )
        except Exception:
            return Response({"error": "Budowa nie znaleziona"}, status=404)

        # Geocoding jeśli brak
        if not (budowa.lat and budowa.lon):
            geocode_budowa(budowa)

        if not (budowa.lat and budowa.lon):
            return Response(
                {"error": "Brak współrzędnych GPS dla tej budowy."},
                status=status.HTTP_422_UNPROCESSABLE_ENTITY,
            )

        markety = szukaj_marketow(budowa.lat, budowa.lon, radius_m=radius)

        return Response({
            "budowa_lat": budowa.lat,
            "budowa_lon": budowa.lon,
            "radius_m": radius,
            "wyniki": [
                {
                    "osm_id": m.osm_id,
                    "nazwa": m.nazwa,
                    "adres": m.adres,
                    "lat": m.lat,
                    "lon": m.lon,
                    "marka": m.marka,
                }
                for m in markety
            ],
        })

    @action(detail=False, methods=["get"], url_path="statystyki")
    def statystyki(self, request):
        """Statystyki dziennika dla budowy — do widoku podsumowania."""
        budowa_id = request.query_params.get("budowa")
        if not budowa_id:
            return Response({"error": "Wymagany ?budowa="}, status=400)

        from django.db.models import Avg, Count, Sum
        qs = WpisDziennika.objects.filter(
            company_id=_company_id(request), budowa_id=budowa_id
        )
        agg = qs.aggregate(
            liczba_wpisow=Count("id"),
            suma_godzin=Sum("godziny_pracy"),
            srednia_pracownicy=Avg("liczba_pracownikow"),
        )

        # Najczęstsza pogoda
        pogody = list(
            qs.values("pogoda")
            .annotate(cnt=Count("pogoda"))
            .order_by("-cnt")[:3]
        )

        return Response({
            **agg,
            "najczestsze_pogody": pogody,
        })
