from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Budowa, EtapBudowy
from .serializers import BudowaSerializer, BudowaListSerializer, EtapBudowySerializer


class BudowaViewSet(viewsets.ModelViewSet):
    serializer_class = BudowaSerializer

    def get_queryset(self):
        company_id = self.request.headers.get("X-Company-Id", 1)
        return Budowa.objects.filter(company_id=company_id).prefetch_related("etapy")

    def get_serializer_class(self):
        if self.action == "list":
            return BudowaListSerializer
        return BudowaSerializer

    def perform_create(self, serializer):
        company_id = self.request.headers.get("X-Company-Id", 1)
        serializer.save(company_id=company_id, created_by=1)  # TODO: real user from JWT

    @action(detail=True, methods=["post"], url_path="etapy")
    def add_etap(self, request, pk=None):
        budowa = self.get_object()
        serializer = EtapBudowySerializer(data={**request.data, "budowa": budowa.pk})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["get"], url_path="summary")
    def summary(self, request, pk=None):
        budowa = self.get_object()
        etapy = budowa.etapy.all()
        zakonczone = etapy.filter(status="zakończony").count()
        return Response({
            "id": budowa.pk,
            "nazwa": budowa.nazwa,
            "status": budowa.status,
            "budzet": budowa.budzet,
            "etapy_total": etapy.count(),
            "etapy_zakonczone": zakonczone,
            "postep_procent": round(zakonczone / etapy.count() * 100) if etapy else 0,
        })


class EtapBudowyViewSet(viewsets.ModelViewSet):
    serializer_class = EtapBudowySerializer

    def get_queryset(self):
        return EtapBudowy.objects.filter(
            budowa__company_id=self.request.headers.get("X-Company-Id", 1)
        )
