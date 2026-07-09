from django.db.models import Q
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Material, HistoriaCeny, PozycjaZamowienia, StatusPozycji
from .serializers import (
    MaterialListSerializer, MaterialDetailSerializer,
    MaterialWriteSerializer, HistoriaCenySerializer,
    PozycjaZamowieniaSerializer,
)


def company_id(request):
    return int(request.headers.get('X-Company-Id', 1))


class MaterialViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        qs = Material.objects.filter(company_id=company_id(self.request))
        q = self.request.query_params.get('q', '').strip()
        if q:
            qs = qs.filter(
                Q(nazwa__icontains=q) |
                Q(producent__icontains=q) |
                Q(symbol__icontains=q)
            )
        kat = self.request.query_params.get('kategoria')
        if kat:
            qs = qs.filter(kategoria=kat)
        return qs

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return MaterialDetailSerializer
        if self.action in ('create', 'update', 'partial_update'):
            return MaterialWriteSerializer
        return MaterialListSerializer

    def perform_create(self, serializer):
        obj = serializer.save(company_id=company_id(self.request))
        # Jeśli podano cenę startową, zapisz też w historii
        if obj.cena_netto:
            HistoriaCeny.objects.create(
                material=obj,
                cena_netto=obj.cena_netto,
                zrodlo='reczne',
            )

    @action(detail=True, methods=['post'], url_path='cena')
    def dodaj_cene(self, request, pk=None):
        """POST /materialy/{id}/cena/ — dodaje wpis historii cen."""
        material = self.get_object()
        cena = request.data.get('cena_netto')
        zrodlo = request.data.get('zrodlo', 'reczne')
        uwagi = request.data.get('uwagi', '')

        if cena is None:
            return Response(
                {'detail': 'Pole cena_netto jest wymagane.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        material.aktualizuj_cene(cena, zrodlo=zrodlo)
        if uwagi:
            h = material.historia_cen.order_by('-data').first()
            if h:
                h.uwagi = uwagi
                h.save(update_fields=['uwagi'])

        return Response(MaterialDetailSerializer(material).data)

    @action(detail=True, methods=['get'], url_path='historia')
    def historia(self, request, pk=None):
        """GET /materialy/{id}/historia/ — pełna historia cen (dla wykresu)."""
        material = self.get_object()
        dni = int(request.query_params.get('dni', 90))
        from django.utils import timezone
        from datetime import timedelta
        od = timezone.now().date() - timedelta(days=dni)
        qs = material.historia_cen.filter(data__gte=od).order_by('data')
        return Response(HistoriaCenySerializer(qs, many=True).data)

    @action(detail=False, methods=['get'], url_path='trendy')
    def trendy(self, request):
        """
        GET /materialy/trendy/ — materiały z wyraźnym trendem cenowym.
        Przydatne dla Emmy i dashboardu.
        """
        qs = self.get_queryset().prefetch_related('historia_cen')
        result = []
        for m in qs:
            historia = list(
                m.historia_cen.order_by('data').values_list('cena_netto', flat=True)[-5:]
            )
            if len(historia) < 2:
                continue
            zmiana = float(historia[-1]) - float(historia[0])
            zmiana_procent = zmiana / float(historia[0]) * 100 if historia[0] else 0
            if abs(zmiana_procent) < 2:
                continue
            s = MaterialListSerializer(m).data
            s['zmiana_procent'] = round(zmiana_procent, 1)
            s['historia_skrot'] = [float(c) for c in historia]
            result.append(s)
        result.sort(key=lambda x: abs(x['zmiana_procent']), reverse=True)
        return Response(result[:20])


class PozycjaZamowieniaViewSet(viewsets.ModelViewSet):
    serializer_class = PozycjaZamowieniaSerializer

    def get_queryset(self):
        qs = PozycjaZamowienia.objects.filter(
            company_id=company_id(self.request)
        ).select_related('material')

        budowa = self.request.query_params.get('budowa')
        if budowa:
            qs = qs.filter(budowa_id=budowa)

        kosztorys = self.request.query_params.get('kosztorys')
        if kosztorys:
            qs = qs.filter(kosztorys_id=kosztorys)

        stat = self.request.query_params.get('status')
        if stat:
            qs = qs.filter(status=stat)

        return qs

    def perform_create(self, serializer):
        serializer.save(company_id=company_id(self.request))

    @action(detail=True, methods=['patch'], url_path='status')
    def zmien_status(self, request, pk=None):
        pozycja = self.get_object()
        nowy_status = request.data.get('status')
        if nowy_status not in StatusPozycji.values:
            return Response(
                {'detail': f'Nieprawidłowy status. Dozwolone: {StatusPozycji.values}'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        pozycja.status = nowy_status
        # Auto-ustaw daty
        from django.utils import timezone
        today = timezone.now().date()
        if nowy_status == StatusPozycji.ZAMOWIONE and not pozycja.data_zamowienia:
            pozycja.data_zamowienia = today
        if nowy_status == StatusPozycji.DOSTARCZONE and not pozycja.data_dostawy:
            pozycja.data_dostawy = today
        pozycja.save()
        return Response(self.get_serializer(pozycja).data)

    @action(detail=True, methods=['patch'], url_path='dostawa')
    def aktualizuj_dostawe(self, request, pk=None):
        """PATCH — aktualizuj ilość dostarczoną."""
        pozycja = self.get_object()
        ilosc = request.data.get('ilosc_dostarczona')
        if ilosc is None:
            return Response({'detail': 'Wymagane: ilosc_dostarczona'}, status=400)
        pozycja.ilosc_dostarczona = ilosc
        if float(ilosc) >= float(pozycja.ilosc):
            pozycja.status = StatusPozycji.DOSTARCZONE
        elif float(ilosc) > 0:
            pozycja.status = StatusPozycji.W_DOSTAWIE
        pozycja.save()
        return Response(self.get_serializer(pozycja).data)

    @action(detail=False, methods=['post'], url_path='z-kosztorysu')
    def importuj_z_kosztorysu(self, request):
        """
        POST — importuje pozycje materiałowe z kosztorysu.
        Body: {budowa_id, kosztorys_id, pozycje: [{material_id, ilosc, cena_netto, etap_id}]}
        """
        cid = company_id(request)
        budowa_id = request.data.get('budowa_id')
        kosztorys_id = request.data.get('kosztorys_id')
        pozycje_raw = request.data.get('pozycje', [])

        created = []
        for p in pozycje_raw:
            try:
                mat = Material.objects.get(id=p['material_id'], company_id=cid)
            except Material.DoesNotExist:
                continue

            obj, _ = PozycjaZamowienia.objects.get_or_create(
                company_id=cid,
                material=mat,
                budowa_id=budowa_id,
                kosztorys_id=kosztorys_id,
                defaults={
                    'ilosc': p.get('ilosc', 1),
                    'etap_id': p.get('etap_id'),
                    'cena_netto_zakupu': p.get('cena_netto'),
                    'status': StatusPozycji.DO_ZAMOWIENIA,
                },
            )
            created.append(obj)

        return Response(
            PozycjaZamowieniaSerializer(created, many=True).data,
            status=status.HTTP_201_CREATED,
        )
