from django.db.models import Q
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import (
    Pracownik, UmiejetnoscPracownika, HistoriaStawki,
    PracownikNaBudowie, Specjalizacja, PoziomDoswiadczenia,
)
from .serializers import (
    PracownikListSerializer, PracownikDetailSerializer,
    PracownikWriteSerializer, UmiejetnoscSerializer,
    HistoriaStawkiSerializer, PracownikNaBudowieSerializer,
)


def cid(request):
    return int(request.headers.get('X-Company-Id', 1))


class PracownikViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        qs = Pracownik.objects.filter(
            company_id=cid(self.request)
        ).prefetch_related('umiejetnosci', 'stawki')

        q = self.request.query_params.get('q', '').strip()
        if q:
            qs = qs.filter(
                Q(imie__icontains=q) |
                Q(nazwisko__icontains=q) |
                Q(telefon__icontains=q)
            )
        spec = self.request.query_params.get('specjalizacja')
        if spec:
            qs = qs.filter(umiejetnosci__specjalizacja=spec)

        if self.request.query_params.get('aktywni') == '1':
            qs = qs.filter(aktywny=True)

        return qs.distinct()

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return PracownikDetailSerializer
        if self.action in ('create', 'update', 'partial_update'):
            return PracownikWriteSerializer
        return PracownikListSerializer

    def perform_create(self, serializer):
        serializer.save(company_id=cid(self.request))

    @action(detail=False, methods=['get'], url_path='do-budowy')
    def do_budowy(self, request):
        """
        GET /pracownicy/do-budowy/?budowa_id=X
        Zwraca pracowników przypisanych do budowy z ich umiejętnościami.
        """
        budowa_id = request.query_params.get('budowa_id')
        if not budowa_id:
            return Response({'detail': 'Wymagany parametr budowa_id'}, status=400)

        powiazania = PracownikNaBudowie.objects.filter(
            company_id=cid(request),
            budowa_id=budowa_id,
            aktywny=True,
        ).select_related('pracownik').prefetch_related(
            'pracownik__umiejetnosci', 'pracownik__stawki'
        )

        result = []
        for p in powiazania:
            data = PracownikDetailSerializer(p.pracownik).data
            data['rola_na_budowie'] = p.rola_na_budowie
            data['data_od'] = str(p.data_od) if p.data_od else None
            data['data_do'] = str(p.data_do) if p.data_do else None
            result.append(data)

        return Response(result)

    @action(detail=True, methods=['post'], url_path='stawka')
    def dodaj_stawke(self, request, pk=None):
        pracownik = self.get_object()
        s = request.data.get('stawka_godz')
        data_od = request.data.get('data_od')
        if not s or not data_od:
            return Response({'detail': 'Wymagane: stawka_godz, data_od'}, status=400)
        h = HistoriaStawki.objects.create(
            pracownik=pracownik,
            stawka_godz=s,
            data_od=data_od,
            uwagi=request.data.get('uwagi', ''),
        )
        return Response(HistoriaStawkiSerializer(h).data, status=201)

    @action(detail=False, methods=['get'], url_path='dobierz-do-knr')
    def dobierz_do_knr(self, request):
        """
        GET /pracownicy/dobierz-do-knr/?specjalizacja=murarz&budowa_id=X&ilosc=2
        AI endpoint — zwraca najlepszych pracowników do danej pozycji KNR.
        Filtruje po: specjalizacja, dostępność na budowie, poziom.
        """
        spec = request.query_params.get('specjalizacja')
        budowa_id = request.query_params.get('budowa_id')
        ilosc = int(request.query_params.get('ilosc', 1))

        company = cid(request)

        qs = Pracownik.objects.filter(
            company_id=company,
            aktywny=True,
            umiejetnosci__specjalizacja=spec,
        ).prefetch_related('umiejetnosci', 'stawki').distinct()

        # Priorytet: pracownicy już na budowie
        if budowa_id:
            na_budowie_ids = PracownikNaBudowie.objects.filter(
                company_id=company,
                budowa_id=budowa_id,
                aktywny=True,
            ).values_list('pracownik_id', flat=True)
            # Sortuj: najpierw na budowie, potem reszta
            na_budowie = qs.filter(id__in=na_budowie_ids)
            pozostali = qs.exclude(id__in=na_budowie_ids)
            qs_sorted = list(na_budowie) + list(pozostali)
        else:
            qs_sorted = list(qs)

        # Sortuj po poziomie (senior > mid > junior)
        poziom_waga = {
            'ekspert': 5, 'senior': 4, 'mid': 3, 'junior': 2, 'uczen': 1
        }

        def _score(p):
            um = next(
                (u for u in p.umiejetnosci.all() if u.specjalizacja == spec),
                None
            )
            return poziom_waga.get(um.poziom if um else 'uczen', 1)

        qs_sorted.sort(key=_score, reverse=True)
        wybrani = qs_sorted[:ilosc]

        result = []
        for p in wybrani:
            um = next(
                (u for u in p.umiejetnosci.all() if u.specjalizacja == spec),
                None
            )
            result.append({
                **PracownikDetailSerializer(p).data,
                'dopasowanie_specjalizacja': spec,
                'poziom_dopasowania': um.poziom if um else None,
                'certyfikat_wazny': um.certyfikat_wazny if um else None,
                'stawka_godz': p.aktualna_stawka,
            })

        return Response(result)

    @action(detail=True, methods=['get', 'post'], url_path='umiejetnosci')
    def umiejetnosci(self, request, pk=None):
        """
        GET  /pracownicy/{id}/umiejetnosci/  — lista umiejętności
        POST /pracownicy/{id}/umiejetnosci/  — dodaj umiejętność
        """
        pracownik = self.get_object()
        if request.method == 'GET':
            qs = UmiejetnoscPracownika.objects.filter(pracownik=pracownik)
            return Response(UmiejetnoscSerializer(qs, many=True).data)
        s = UmiejetnoscSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        s.save(pracownik=pracownik)
        return Response(s.data, status=201)

    @action(detail=True, methods=['patch', 'delete'],
            url_path=r'umiejetnosci/(?P<um_pk>\d+)')
    def umiejetnosc_detail(self, request, pk=None, um_pk=None):
        """
        PATCH  /pracownicy/{id}/umiejetnosci/{um_id}/
        DELETE /pracownicy/{id}/umiejetnosci/{um_id}/
        """
        pracownik = self.get_object()
        try:
            um = UmiejetnoscPracownika.objects.get(pk=um_pk, pracownik=pracownik)
        except UmiejetnoscPracownika.DoesNotExist:
            return Response(status=404)
        if request.method == 'DELETE':
            um.delete()
            return Response(status=204)
        s = UmiejetnoscSerializer(um, data=request.data, partial=True)
        s.is_valid(raise_exception=True)
        s.save()
        return Response(s.data)


class PracownikNaBudowieViewSet(viewsets.ModelViewSet):
    serializer_class = PracownikNaBudowieSerializer

    def get_queryset(self):
        return PracownikNaBudowie.objects.filter(
            company_id=cid(self.request)
        ).select_related('pracownik')

    def perform_create(self, serializer):
        serializer.save(company_id=cid(self.request))
