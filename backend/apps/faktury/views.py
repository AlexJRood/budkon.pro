from datetime import date
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Faktura, StatusFaktury
from .serializers import FakturaListSerializer, FakturaDetailSerializer, FakturaWriteSerializer


def _cid(request) -> int:
    try:
        return int(request.headers.get('X-Company-Id', 1))
    except (TypeError, ValueError):
        return 1


class FakturaViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        qs = Faktura.objects.filter(company_id=_cid(self.request)).select_related('budowa')
        if b := self.request.query_params.get('budowa'):
            qs = qs.filter(budowa_id=b)
        if s := self.request.query_params.get('status'):
            qs = qs.filter(status=s)
        return qs

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return FakturaDetailSerializer
        if self.action in ('create', 'update', 'partial_update'):
            return FakturaWriteSerializer
        return FakturaListSerializer

    def perform_create(self, serializer):
        serializer.save(company_id=_cid(self.request))

    @action(detail=False, methods=['post'], url_path='z-oferty')
    def z_oferty(self, request):
        """POST /faktury/z-oferty/ {oferta_id: X} — tworzy FV z oferty."""
        from apps.oferty.models import Oferta
        try:
            oferta = Oferta.objects.get(pk=request.data['oferta_id'],
                                        company_id=_cid(request))
        except (Oferta.DoesNotExist, KeyError):
            return Response({'detail': 'Oferta nie znaleziona'}, status=400)

        fv = Faktura.z_oferty(
            oferta,
            wystawca_nazwa=request.data.get('wystawca_nazwa', ''),
            wystawca_nip=request.data.get('wystawca_nip', ''),
            wystawca_adres=request.data.get('wystawca_adres', ''),
            wystawca_konto=request.data.get('wystawca_konto', ''),
        )
        fv.save()
        return Response(FakturaDetailSerializer(fv).data, status=201)

    @action(detail=True, methods=['post'], url_path='wyslij')
    def wyslij(self, request, pk=None):
        """Zmień status na 'wyslana'."""
        fv = self.get_object()
        if fv.status == StatusFaktury.SZKIC:
            fv.status = StatusFaktury.WYSTAWIONA
            fv.numer = fv._generuj_numer()
        fv.status = StatusFaktury.WYSLANA
        fv.save()
        return Response(FakturaListSerializer(fv).data)

    @action(detail=True, methods=['post'], url_path='oplacona')
    def oznacz_oplacona(self, request, pk=None):
        """Zmień status na 'oplacona'."""
        fv = self.get_object()
        fv.status = StatusFaktury.OPLACONA
        fv.data_oplacenia = request.data.get('data_oplacenia') or date.today().isoformat()
        fv.save()
        return Response(FakturaListSerializer(fv).data)

    @action(detail=False, methods=['get'], url_path='do-oplacenia')
    def do_oplacenia(self, request):
        """Faktury wystawione ale nie opłacone — widget dla Emmy."""
        qs = Faktura.objects.filter(
            company_id=_cid(request),
            status__in=[StatusFaktury.WYSTAWIONA, StatusFaktury.WYSLANA],
        ).order_by('termin_platnosci')
        return Response(FakturaListSerializer(qs, many=True).data)
