from rest_framework import serializers
from .models import Budowa, EtapBudowy


class EtapBudowySerializer(serializers.ModelSerializer):
    class Meta:
        model = EtapBudowy
        fields = "__all__"


class BudowaSerializer(serializers.ModelSerializer):
    etapy = EtapBudowySerializer(many=True, read_only=True)

    class Meta:
        model = Budowa
        fields = "__all__"


class BudowaListSerializer(serializers.ModelSerializer):
    """Lighter serializer for list views — no nested etapy."""
    etapy_count = serializers.SerializerMethodField()
    postep = serializers.SerializerMethodField()

    class Meta:
        model = Budowa
        fields = [
            "id", "nazwa", "adres", "status", "data_rozpoczecia",
            "data_planowanego_zakonczenia", "budzet", "etapy_count", "postep",
        ]

    def get_etapy_count(self, obj):
        return obj.etapy.count()

    def get_postep(self, obj):
        etapy = obj.etapy.all()
        if not etapy:
            return 0
        zakonczone = etapy.filter(status="zakończony").count()
        return round(zakonczone / etapy.count() * 100)
