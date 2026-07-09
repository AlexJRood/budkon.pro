import os
from django.http import HttpResponse, Http404
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Oferta, HistoriaStatusuOferty, StatusOferty
from .serializers import (
    OfertyListSerializer, OfertyDetailSerializer, OfertyWriteSerializer,
)
from .pdf import generuj_pdf


def company_id(request):
    return int(request.headers.get('X-Company-Id', 1))


class OfertyViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        qs = Oferta.objects.filter(company_id=company_id(self.request))
        budowa = self.request.query_params.get('budowa')
        if budowa:
            qs = qs.filter(budowa_id=budowa)
        stat = self.request.query_params.get('status')
        if stat:
            qs = qs.filter(status=stat)
        return qs

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return OfertyDetailSerializer
        if self.action in ('create', 'update', 'partial_update'):
            return OfertyWriteSerializer
        return OfertyListSerializer

    def perform_create(self, serializer):
        oferta = serializer.save(
            company_id=company_id(self.request),
            created_by=getattr(self.request.user, 'id', 1),
        )
        HistoriaStatusuOferty.objects.create(
            oferta=oferta,
            status=oferta.status,
        )

    @action(detail=False, methods=['post'], url_path='z-kosztorysu')
    def z_kosztorysu(self, request):
        """
        POST /oferty/z-kosztorysu/
        Body: {kosztorys_id, klient_nazwa, klient_email?, klient_telefon?,
               klient_adres?, klient_nip?, tytul?, wstep?, warunki?,
               vat_procent?, rabat_procent?, wazna_do?}
        Tworzy ofertę ze snapshotem pozycji z kosztorysu.
        """
        from apps.kosztorysy.models import Kosztorys

        cid = company_id(request)
        kosztorys_id = request.data.get('kosztorys_id')

        try:
            kosztorys = Kosztorys.objects.prefetch_related(
                'dzialy__pozycje'
            ).get(id=kosztorys_id, company_id=cid)
        except Kosztorys.DoesNotExist:
            return Response(
                {'detail': 'Kosztorys nie znaleziony.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Dane firmy (wystawcy) — domyślne z company settings lub puste
        oferta = Oferta.z_kosztorysu(
            kosztorys,
            company_id=cid,
            budowa_id=kosztorys.budowa_id,
            kosztorys_id=kosztorys.id,
            tytul=request.data.get('tytul') or f'Oferta — {kosztorys.nazwa}',
            klient_nazwa=request.data.get('klient_nazwa', ''),
            klient_adres=request.data.get('klient_adres', ''),
            klient_nip=request.data.get('klient_nip', ''),
            klient_email=request.data.get('klient_email', ''),
            klient_telefon=request.data.get('klient_telefon', ''),
            wystawca_nazwa=request.data.get('wystawca_nazwa', ''),
            wystawca_adres=request.data.get('wystawca_adres', ''),
            wystawca_nip=request.data.get('wystawca_nip', ''),
            wystawca_email=request.data.get('wystawca_email', ''),
            wystawca_telefon=request.data.get('wystawca_telefon', ''),
            wstep=request.data.get('wstep', ''),
            warunki=request.data.get('warunki', ''),
            uwagi=request.data.get('uwagi', ''),
            vat_procent=int(request.data.get('vat_procent', 23)),
            rabat_procent=request.data.get('rabat_procent', 0),
            wazna_do=request.data.get('wazna_do'),
            data_wystawienia=timezone.now().date(),
            created_by=getattr(request.user, 'id', 1),
        )
        oferta.save()
        HistoriaStatusuOferty.objects.create(oferta=oferta, status=oferta.status)

        return Response(
            OfertyDetailSerializer(oferta).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['get', 'post'], url_path='pdf')
    def pdf(self, request, pk=None):
        """
        GET  — pobiera wygenerowany PDF (inline lub attachment)
        POST — (re)generuje PDF
        """
        oferta = self.get_object()

        if request.method == 'POST' or not oferta.pdf_url:
            pdf_bytes = generuj_pdf(oferta)
            if pdf_bytes is None:
                return Response(
                    {'detail': 'reportlab nie zainstalowany — PDF niedostępny.'},
                    status=status.HTTP_501_NOT_IMPLEMENTED,
                )
            # Zapisz do media/oferty/
            import pathlib
            katalog = pathlib.Path('media/oferty')
            katalog.mkdir(parents=True, exist_ok=True)
            sciezka = katalog / f'oferta_{oferta.id}.pdf'
            sciezka.write_bytes(pdf_bytes)
            oferta.pdf_url = str(sciezka)
            oferta.save(update_fields=['pdf_url'])

        # Zwróć PDF inline
        try:
            pdf_bytes = open(oferta.pdf_url, 'rb').read()
        except (FileNotFoundError, TypeError):
            raise Http404('PDF nie istnieje — wygeneruj go ponownie.')

        response = HttpResponse(pdf_bytes, content_type='application/pdf')
        inline = request.query_params.get('download') != '1'
        disposition = 'inline' if inline else 'attachment'
        response['Content-Disposition'] = (
            f'{disposition}; filename="oferta_{oferta.numer}.pdf"'
        )
        return response

    @action(detail=True, methods=['patch'], url_path='status')
    def zmien_status(self, request, pk=None):
        oferta = self.get_object()
        nowy = request.data.get('status')
        uwagi = request.data.get('uwagi', '')

        if nowy not in StatusOferty.values:
            return Response(
                {'detail': f'Niedozwolony status. Dostępne: {StatusOferty.values}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        oferta.status = nowy
        oferta.save(update_fields=['status', 'updated_at'])
        HistoriaStatusuOferty.objects.create(
            oferta=oferta, status=nowy, uwagi=uwagi
        )
        return Response(OfertyDetailSerializer(oferta).data)

    @action(detail=True, methods=['post'], url_path='duplikuj')
    def duplikuj(self, request, pk=None):
        """Klonuje ofertę jako roboczy szkic."""
        oferta = self.get_object()
        nowa = Oferta(
            company_id=oferta.company_id,
            budowa_id=oferta.budowa_id,
            kosztorys_id=oferta.kosztorys_id,
            tytul=f'{oferta.tytul} (kopia)',
            klient_nazwa=oferta.klient_nazwa,
            klient_adres=oferta.klient_adres,
            klient_nip=oferta.klient_nip,
            klient_email=oferta.klient_email,
            klient_telefon=oferta.klient_telefon,
            wystawca_nazwa=oferta.wystawca_nazwa,
            wystawca_adres=oferta.wystawca_adres,
            wystawca_nip=oferta.wystawca_nip,
            wystawca_email=oferta.wystawca_email,
            wystawca_telefon=oferta.wystawca_telefon,
            wstep=oferta.wstep,
            warunki=oferta.warunki,
            uwagi=oferta.uwagi,
            pozycje=oferta.pozycje,
            wartosc_netto=oferta.wartosc_netto,
            vat_procent=oferta.vat_procent,
            rabat_procent=oferta.rabat_procent,
            status=StatusOferty.ROBOCZY,
            data_wystawienia=timezone.now().date(),
            created_by=getattr(request.user, 'id', 1),
        )
        nowa.save()
        HistoriaStatusuOferty.objects.create(oferta=nowa, status=nowa.status)
        return Response(
            OfertyDetailSerializer(nowa).data,
            status=status.HTTP_201_CREATED,
        )
