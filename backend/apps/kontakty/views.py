from django.db.models import Q
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

from .models import Kontrahent, PowiazaniePodwykonawcy
from .serializers import (
    KontrahentSearchSerializer,
    KontrahentSerializer,
    PowiazanieListSerializer,
    PowiazanieWriteSerializer,
)


def _cid(request) -> int:
    try:
        return int(request.headers.get("X-Company-Id", 1))
    except (TypeError, ValueError):
        return 1


class KontrahentViewSet(viewsets.ModelViewSet):
    """
    Kontrahenci firmy (podwykonawcy, dostawcy, projektanci).

    GET /kontakty/?branza=elektryczna — filtr po branży
    GET /kontakty/?q=kowalski        — wyszukiwanie (name/firma/NIP)
    GET /kontakty/szukaj/?q=...      — lekki endpoint dla pickera
    """

    parser_classes = [MultiPartParser, FormParser]

    def get_serializer_class(self):
        return KontrahentSerializer

    def get_queryset(self):
        cid = _cid(self.request)
        qs = Kontrahent.objects.filter(company_id=cid)

        if branza := self.request.query_params.get("branza"):
            qs = qs.filter(branza=branza)

        if q := self.request.query_params.get("q", "").strip():
            qs = qs.filter(
                Q(imie__icontains=q)
                | Q(nazwisko__icontains=q)
                | Q(firma__icontains=q)
                | Q(nip__icontains=q)
                | Q(email__icontains=q)
                | Q(telefon__icontains=q)
            )

        return qs

    def perform_create(self, serializer):
        serializer.save(company_id=_cid(self.request))

    @action(detail=False, methods=["get"], url_path="szukaj")
    def szukaj(self, request):
        """Lekki endpoint dla contact picker w Flutter."""
        q = request.query_params.get("q", "").strip()
        limit = min(int(request.query_params.get("limit", 20)), 50)

        qs = Kontrahent.objects.filter(company_id=_cid(request))
        if q:
            qs = qs.filter(
                Q(imie__icontains=q)
                | Q(nazwisko__icontains=q)
                | Q(firma__icontains=q)
                | Q(telefon__icontains=q)
            )

        qs = qs[:limit]
        return Response(
            KontrahentSearchSerializer(
                qs, many=True, context={"request": request}
            ).data
        )


class PowiazaniePodwykonawcyViewSet(viewsets.ModelViewSet):
    """
    Powiązania podwykonawców z budową.
    GET  /podwykonawcy/?budowa=<id>  — lista dla budowy
    POST /podwykonawcy/              — {budowa_id, kontrahent_id, rola, ...}
    """

    def get_queryset(self):
        cid = _cid(self.request)
        qs = PowiazaniePodwykonawcy.objects.filter(company_id=cid).select_related(
            "kontrahent", "etap"
        )
        if budowa_id := self.request.query_params.get("budowa"):
            qs = qs.filter(budowa_id=budowa_id)
        if status := self.request.query_params.get("status"):
            qs = qs.filter(status=status)
        return qs

    def get_serializer_class(self):
        if self.action in ("create", "update", "partial_update"):
            return PowiazanieWriteSerializer
        return PowiazanieListSerializer

    def perform_create(self, serializer):
        cid = _cid(self.request)
        budowa_id = self.request.data.get("budowa_id")
        serializer.save(company_id=cid, budowa_id=budowa_id)

    @action(detail=True, methods=["patch"], url_path="status")
    def zmien_status(self, request, pk=None):
        p = self.get_object()
        p.status = request.data.get("status", p.status)
        p.save(update_fields=["status"])
        return Response(PowiazanieListSerializer(p).data)
