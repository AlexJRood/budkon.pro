from rest_framework import serializers

from .models import EmmaWiadomoscPrzetargu, FetchLog, Przetarg, SubskrypcjaPrzetargow


class PrzetargListSerializer(serializers.ModelSerializer):
    dni_do_terminu = serializers.ReadOnlyField()

    class Meta:
        model = Przetarg
        fields = [
            "id",
            "tytul",
            "zamawiajacy",
            "wartosc_szacunkowa",
            "waluta",
            "termin_skladania",
            "lokalizacja",
            "cpv_kody",
            "status",
            "ai_score",
            "ai_czy_warto",
            "ai_uwagi",
            "zrodlo",
            "zrodlo_url",
            "kosztorys_id",
            "dni_do_terminu",
            "created_at",
        ]


class PrzetargDetailSerializer(serializers.ModelSerializer):
    dni_do_terminu = serializers.ReadOnlyField()

    class Meta:
        model = Przetarg
        fields = "__all__"


class PrzetargWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Przetarg
        fields = [
            "tytul",
            "zamawiajacy",
            "opis",
            "wartosc_szacunkowa",
            "waluta",
            "termin_skladania",
            "termin_realizacji",
            "lokalizacja",
            "cpv_kody",
            "status",
            "zrodlo_url",
        ]


class SubskrypcjaSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubskrypcjaPrzetargow
        fields = [
            "id",
            "nazwa",
            "cpv_kody",
            "regiony",
            "wartosc_min",
            "wartosc_max",
            "slowa_kluczowe",
            "aktywna",
            "ostatnie_pobranie",
            "created_at",
        ]
        read_only_fields = ["ostatnie_pobranie", "created_at"]


class EmmaWiadomoscSerializer(serializers.ModelSerializer):
    przetarg_tytul = serializers.CharField(source="przetarg.tytul", read_only=True)
    przetarg_wartosc = serializers.DecimalField(
        source="przetarg.wartosc_szacunkowa",
        max_digits=14,
        decimal_places=2,
        read_only=True,
    )
    przetarg_ai_score = serializers.IntegerField(
        source="przetarg.ai_score", read_only=True
    )
    przetarg_termin_skladania = serializers.DateTimeField(
        source="przetarg.termin_skladania", read_only=True
    )
    przetarg_lokalizacja = serializers.CharField(
        source="przetarg.lokalizacja", read_only=True
    )

    class Meta:
        model = EmmaWiadomoscPrzetargu
        fields = [
            "id",
            "przetarg_id",
            "przetarg_tytul",
            "przetarg_wartosc",
            "przetarg_ai_score",
            "przetarg_termin_skladania",
            "przetarg_lokalizacja",
            "tekst",
            "kosztorys_id",
            "przeczytana",
            "zaakceptowana",
            "created_at",
        ]


class FetchLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = FetchLog
        fields = [
            "id",
            "zrodlo",
            "started_at",
            "finished_at",
            "count_fetched",
            "count_new",
            "blad",
        ]
