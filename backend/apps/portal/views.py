from django.http import Http404, JsonResponse
from django.shortcuts import get_object_or_404, render
from django.utils import timezone
from rest_framework import serializers, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.budowa.models import Budowa
from apps.dziennik.models import WpisDziennika
from apps.faktury.models import Faktura, StatusFaktury
from .models import PortalKlienta


# ─── API do zarządzania portalami (dla mamy) ────────────────────────────────

class PortalSerializer(serializers.ModelSerializer):
    url_klienta = serializers.SerializerMethodField()
    jest_wazny = serializers.BooleanField(read_only=True)

    class Meta:
        model = PortalKlienta
        fields = [
            'id', 'budowa_id', 'token', 'nazwa_klienta',
            'email_klienta', 'telefon_klienta',
            'pokazuj_kosztorys', 'pokazuj_faktury',
            'pokazuj_zdjecia', 'pokazuj_harmonogram',
            'aktywny', 'wygasa', 'jest_wazny',
            'created_at', 'ostatni_odczyt', 'liczba_odczytow',
            'url_klienta',
        ]
        read_only_fields = ['token', 'created_at', 'ostatni_odczyt', 'liczba_odczytow']

    def get_url_klienta(self, obj):
        request = self.context.get('request')
        path = obj.get_absolute_url()
        if request:
            return request.build_absolute_uri(path)
        return path


class PortalViewSet(viewsets.ModelViewSet):
    serializer_class = PortalSerializer

    def get_queryset(self):
        cid = int(self.request.headers.get('X-Company-Id', 1))
        qs = PortalKlienta.objects.filter(company_id=cid).select_related('budowa')
        if b := self.request.query_params.get('budowa'):
            qs = qs.filter(budowa_id=b)
        return qs

    def perform_create(self, serializer):
        cid = int(self.request.headers.get('X-Company-Id', 1))
        serializer.save(company_id=cid)

    @action(detail=True, methods=['post'], url_path='dezaktywuj')
    def dezaktywuj(self, request, pk=None):
        portal = self.get_object()
        portal.aktywny = False
        portal.save(update_fields=['aktywny'])
        return Response({'status': 'dezaktywowany'})

    @action(detail=True, methods=['post'], url_path='regeneruj-token')
    def regeneruj_token(self, request, pk=None):
        import secrets
        portal = self.get_object()
        portal.token = secrets.token_urlsafe(48)
        portal.save(update_fields=['token'])
        return Response(PortalSerializer(portal, context={'request': request}).data)


# ─── Widok HTML dla klienta ─────────────────────────────────────────────────

def portal_klienta(request, token: str):
    portal = get_object_or_404(PortalKlienta, token=token)

    if not portal.jest_wazny:
        return render(request, 'portal/wygasl.html', {'portal': portal}, status=403)

    portal.zarejestruj_odczyt()

    budowa = portal.budowa
    etapy = list(budowa.etapy.all().order_by('kolejnosc'))

    # Postęp
    postep = budowa.postep
    etapy_zakonczone = sum(1 for e in etapy if e.status == 'zakończony')

    # Ostatnie zdjęcia z dziennika
    zdjecia = []
    if portal.pokazuj_zdjecia:
        wpisy = WpisDziennika.objects.filter(
            budowa=budowa
        ).prefetch_related('zdjecia').order_by('-data')[:10]
        for wpis in wpisy:
            for z in wpis.zdjecia.all():
                if z.plik:
                    zdjecia.append({
                        'url': request.build_absolute_uri(z.plik.url),
                        'opis': z.opis,
                        'data': wpis.data,
                    })
                if len(zdjecia) >= 12:
                    break
            if len(zdjecia) >= 12:
                break

    # Faktury klienta
    faktury = []
    if portal.pokazuj_faktury:
        faktury = list(
            Faktura.objects.filter(
                budowa=budowa,
                status__in=[
                    StatusFaktury.WYSTAWIONA,
                    StatusFaktury.WYSLANA,
                    StatusFaktury.OPLACONA,
                ]
            ).order_by('-data_wystawienia')
        )

    # Ostatnie wpisy dziennika (bez zdjęć — tylko opis)
    ostatnie_wpisy = list(
        WpisDziennika.objects.filter(budowa=budowa)
        .order_by('-data')[:5]
        .values('data', 'opis', 'pogoda', 'temperatura', 'liczba_pracownikow')
    )

    context = {
        'portal': portal,
        'budowa': budowa,
        'etapy': etapy,
        'etapy_zakonczone': etapy_zakonczone,
        'postep': postep,
        'zdjecia': zdjecia,
        'faktury': faktury,
        'ostatnie_wpisy': ostatnie_wpisy,
        'teraz': timezone.now(),
    }
    return render(request, 'portal/budowa.html', context)
