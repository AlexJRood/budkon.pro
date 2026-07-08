import asyncio
from decimal import Decimal

from django.conf import settings
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import KnrKatalog, KnrPozycja, Kosztorys, KosztorysdzDzial, KosztorysPozycja
from .serializers import (
    KnrKatalogSerializer,
    KnrPozycjaSerializer,
    KosztorysListSerializer,
    KosztorysSerializer,
    KosztorysWriteSerializer,
    KosztorysdzDzialSerializer,
    KosztorysdzDzialWriteSerializer,
    KosztorysPozycjaSerializer,
    KosztorysPozycjaWriteSerializer,
)
from .ai.pipeline import KosztorysPipeline


def _company_id(request) -> int:
    try:
        return int(request.headers.get("X-Company-Id", 1))
    except (TypeError, ValueError):
        return 1


# ── KNR (read-only, shared across companies) ──────────────────────────────────

class KnrKatalogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = KnrKatalog.objects.all().order_by("kod")
    serializer_class = KnrKatalogSerializer

    @action(detail=True, methods=["get"])
    def pozycje(self, request, pk=None):
        katalog = self.get_object()
        search = request.query_params.get("q", "")
        qs = katalog.pozycje.all()
        if search:
            qs = qs.filter(opis__icontains=search)
        page = self.paginate_queryset(qs)
        if page is not None:
            return self.get_paginated_response(KnrPozycjaSerializer(page, many=True).data)
        return Response(KnrPozycjaSerializer(qs, many=True).data)


class KnrPozycjaViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = KnrPozycjaSerializer

    def get_queryset(self):
        qs = KnrPozycja.objects.select_related("katalog").all()
        q = self.request.query_params.get("q")
        katalog_id = self.request.query_params.get("katalog")
        if q:
            qs = qs.filter(opis__icontains=q)
        if katalog_id:
            qs = qs.filter(katalog_id=katalog_id)
        return qs.order_by("katalog__kod", "numer")


# ── Kosztorys ─────────────────────────────────────────────────────────────────

class KosztorysViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        company_id = _company_id(self.request)
        qs = Kosztorys.objects.filter(company_id=company_id).prefetch_related(
            "dzialy__pozycje__knr_pozycja"
        )
        budowa_id = self.request.query_params.get("budowa")
        if budowa_id:
            qs = qs.filter(budowa_id=budowa_id)
        return qs.order_by("-updated_at")

    def get_serializer_class(self):
        if self.action in ("list",):
            return KosztorysListSerializer
        if self.action in ("create", "update", "partial_update"):
            return KosztorysWriteSerializer
        return KosztorysSerializer

    def perform_create(self, serializer):
        serializer.save(
            company_id=_company_id(self.request),
            created_by=self.request.headers.get("X-User-Id", 1),
        )

    @action(detail=True, methods=["post"], url_path="ai-generate")
    def ai_generate(self, request, pk=None):
        """
        POST /kosztorysy/{id}/ai-generate/
        Body: { "opis": "...", "obmiar": {...} }

        Calls Superbee pipeline → fills the kosztorys with AI-generated dzialy+pozycje.
        Existing dzialy are cleared first.
        """
        kosztorys = self.get_object()
        opis = request.data.get("opis", kosztorys.ai_prompt or kosztorys.nazwa)
        obmiar = request.data.get("obmiar", {})

        superbee_url = getattr(settings, "SUPERBEE_URL", "http://superbee.cloud:8080")
        superbee_token = getattr(settings, "SUPERBEE_TOKEN", "")

        pipeline = KosztorysPipeline(superbee_url=superbee_url, superbee_token=superbee_token)

        try:
            dto = asyncio.run(pipeline.generate(opis=opis, obmiar=obmiar, company_id=kosztorys.company_id))
        except Exception as exc:
            return Response({"detail": f"Pipeline error: {exc}"}, status=status.HTTP_502_BAD_GATEWAY)

        # Clear and rebuild
        kosztorys.dzialy.all().delete()
        kosztorys.ai_prompt = opis
        kosztorys.save(update_fields=["ai_prompt", "updated_at"])

        for i, dzial_dto in enumerate(dto.dzialy):
            dzial = KosztorysdzDzial.objects.create(
                kosztorys=kosztorys, nazwa=dzial_dto.nazwa, kolejnosc=i
            )
            for j, p in enumerate(dzial_dto.pozycje):
                KosztorysPozycja.objects.create(
                    dzial=dzial,
                    knr_pozycja_id=p.knr_pozycja_id,
                    opis=p.opis,
                    jednostka=p.jednostka,
                    ilosc=p.ilosc,
                    cena_jednostkowa=p.cena_jednostkowa,
                    kolejnosc=j,
                    ai_suggested_price=p.ai_suggested_price,
                    ai_suggested_qty=p.ai_suggested_qty,
                )

        kosztorys.refresh_from_db()
        return Response(KosztorysSerializer(kosztorys).data)

    @action(detail=True, methods=["post"], url_path="import-ath2")
    def import_ath2(self, request, pk=None):
        """
        POST /kosztorysy/{id}/import-ath2/
        Multipart: file=<ath2/xml file>

        Parses NormaPro ATH2 export and imports into this kosztorys.
        """
        kosztorys = self.get_object()

        if "file" not in request.FILES:
            return Response({"detail": "Brak pliku."}, status=status.HTTP_400_BAD_REQUEST)

        upload = request.FILES["file"]

        import tempfile, os
        with tempfile.NamedTemporaryFile(suffix=".ath2", delete=False) as tmp:
            for chunk in upload.chunks():
                tmp.write(chunk)
            tmp_path = tmp.name

        try:
            from .parsers.ath2_parser import Ath2Parser
            parser = Ath2Parser()
            parsed = parser.parse(tmp_path)
            parser.import_into(kosztorys.pk, parsed)
        except Exception as exc:
            return Response({"detail": f"Błąd parsowania: {exc}"}, status=status.HTTP_422_UNPROCESSABLE_ENTITY)
        finally:
            os.unlink(tmp_path)

        kosztorys.refresh_from_db()
        return Response(KosztorysSerializer(kosztorys).data)

    @action(detail=True, methods=["get"], url_path="pdf")
    def export_pdf(self, request, pk=None):
        """Placeholder — PDF export will be added when reportlab is set up."""
        return Response({"detail": "PDF export — coming soon."}, status=status.HTTP_501_NOT_IMPLEMENTED)


# ── Dział ─────────────────────────────────────────────────────────────────────

class KosztorysdzDzialViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        company_id = _company_id(self.request)
        return KosztorysdzDzial.objects.filter(
            kosztorys__company_id=company_id
        ).prefetch_related("pozycje").order_by("kolejnosc")

    def get_serializer_class(self):
        if self.action in ("create", "update", "partial_update"):
            return KosztorysdzDzialWriteSerializer
        return KosztorysdzDzialSerializer


# ── Pozycja ───────────────────────────────────────────────────────────────────

class KosztorysPozycjaViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        company_id = _company_id(self.request)
        return KosztorysPozycja.objects.filter(
            dzial__kosztorys__company_id=company_id
        ).select_related("knr_pozycja").order_by("kolejnosc")

    def get_serializer_class(self):
        if self.action in ("create", "update", "partial_update"):
            return KosztorysPozycjaWriteSerializer
        return KosztorysPozycjaSerializer
