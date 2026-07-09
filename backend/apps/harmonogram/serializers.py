from rest_framework import serializers

from apps.budowa.models import EtapBudowy
from .models import MilestoneHarmonogramu, ZadanieHarmonogramu


class ZadanieListSerializer(serializers.ModelSerializer):
    etap_nazwa = serializers.CharField(source="etap.nazwa", read_only=True, default=None)
    opoznienie_dni = serializers.IntegerField(read_only=True)
    poprzednicy_ids = serializers.PrimaryKeyRelatedField(
        source="poprzednicy", many=True, read_only=True
    )

    class Meta:
        model = ZadanieHarmonogramu
        fields = [
            "id",
            "etap",
            "etap_nazwa",
            "nazwa",
            "opis",
            "kolejnosc",
            "status",
            "data_start",
            "data_koniec",
            "czas_trwania_dni",
            "postep_procent",
            "budzet",
            "kosztorys_id",
            "assigned_ids",
            "poprzednicy_ids",
            "opoznienie_dni",
        ]


class ZadanieWriteSerializer(serializers.ModelSerializer):
    poprzednicy = serializers.PrimaryKeyRelatedField(
        many=True,
        queryset=ZadanieHarmonogramu.objects.all(),
        required=False,
    )

    class Meta:
        model = ZadanieHarmonogramu
        fields = [
            "etap",
            "nazwa",
            "opis",
            "kolejnosc",
            "status",
            "data_start",
            "data_koniec",
            "czas_trwania_dni",
            "postep_procent",
            "budzet",
            "kosztorys_id",
            "assigned_ids",
            "poprzednicy",
        ]

    def create(self, validated_data):
        poprzednicy = validated_data.pop("poprzednicy", [])
        zadanie = super().create(validated_data)
        if poprzednicy:
            zadanie.poprzednicy.set(poprzednicy)
        return zadanie

    def update(self, instance, validated_data):
        poprzednicy = validated_data.pop("poprzednicy", None)
        zadanie = super().update(instance, validated_data)
        if poprzednicy is not None:
            zadanie.poprzednicy.set(poprzednicy)
        return zadanie


class MilestoneSerializer(serializers.ModelSerializer):
    etap_nazwa = serializers.CharField(source="etap.nazwa", read_only=True, default=None)

    class Meta:
        model = MilestoneHarmonogramu
        fields = [
            "id",
            "etap",
            "etap_nazwa",
            "nazwa",
            "data",
            "osiagniety",
            "kolor",
        ]


class EtapTimelineSerializer(serializers.ModelSerializer):
    """Etap z zadaniami i milestones — do widoku Gantta."""

    zadania = ZadanieListSerializer(many=True, read_only=True)
    postep_etapu = serializers.SerializerMethodField()

    class Meta:
        model = EtapBudowy
        fields = [
            "id",
            "nazwa",
            "typ",
            "kolejnosc",
            "status",
            "data_start",
            "data_koniec",
            "budzet_etapu",
            "zadania",
            "postep_etapu",
        ]

    def get_postep_etapu(self, obj) -> int:
        zadania = list(obj.zadania.all())
        if not zadania:
            return 100 if obj.status == "zakończony" else 0
        return int(sum(z.postep_procent for z in zadania) / len(zadania))
