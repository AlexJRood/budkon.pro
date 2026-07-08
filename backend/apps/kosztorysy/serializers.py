from decimal import Decimal
from rest_framework import serializers
from .models import KnrKatalog, KnrPozycja, Kosztorys, KosztorysdzDzial, KosztorysPozycja


class KnrKatalogSerializer(serializers.ModelSerializer):
    class Meta:
        model = KnrKatalog
        fields = ["id", "kod", "nazwa", "opis"]


class KnrPozycjaSerializer(serializers.ModelSerializer):
    katalog_kod = serializers.CharField(source="katalog.kod", read_only=True)

    class Meta:
        model = KnrPozycja
        fields = ["id", "katalog", "katalog_kod", "numer", "opis", "jednostka",
                  "naklad_r", "naklad_m", "naklad_s"]


# ── Kosztorys pozycja ─────────────────────────────────────────────────────────

class KosztorysPozycjaSerializer(serializers.ModelSerializer):
    wartosc = serializers.DecimalField(
        max_digits=14, decimal_places=2, read_only=True, source="wartosc"
    )
    knr_numer = serializers.CharField(source="knr_pozycja.numer", read_only=True, default=None)

    class Meta:
        model = KosztorysPozycja
        fields = [
            "id", "dzial", "knr_pozycja", "knr_numer",
            "opis", "jednostka", "ilosc", "cena_jednostkowa", "wartosc",
            "kolejnosc", "ai_suggested_price", "ai_suggested_qty",
        ]
        read_only_fields = ["wartosc"]


class KosztorysPozycjaWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = KosztorysPozycja
        fields = [
            "id", "dzial", "knr_pozycja",
            "opis", "jednostka", "ilosc", "cena_jednostkowa",
            "kolejnosc", "ai_suggested_price", "ai_suggested_qty",
        ]


# ── Dział ─────────────────────────────────────────────────────────────────────

class KosztorysdzDzialSerializer(serializers.ModelSerializer):
    pozycje = KosztorysPozycjaSerializer(many=True, read_only=True)
    wartosc_dzialu = serializers.SerializerMethodField()

    class Meta:
        model = KosztorysdzDzial
        fields = ["id", "kosztorys", "nazwa", "kolejnosc", "pozycje", "wartosc_dzialu"]

    def get_wartosc_dzialu(self, obj) -> Decimal:
        return sum((p.wartosc for p in obj.pozycje.all()), Decimal("0"))


class KosztorysdzDzialWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = KosztorysdzDzial
        fields = ["id", "kosztorys", "nazwa", "kolejnosc"]


# ── Kosztorys ─────────────────────────────────────────────────────────────────

class KosztorysListSerializer(serializers.ModelSerializer):
    wartosc_total = serializers.SerializerMethodField()
    pozycje_count = serializers.SerializerMethodField()

    class Meta:
        model = Kosztorys
        fields = [
            "id", "budowa_id", "nazwa", "opis", "status",
            "wartosc_total", "pozycje_count", "created_at", "updated_at",
        ]

    def get_wartosc_total(self, obj) -> Decimal:
        total = Decimal("0")
        for dzial in obj.dzialy.all():
            for p in dzial.pozycje.all():
                total += p.wartosc
        return total

    def get_pozycje_count(self, obj) -> int:
        return sum(d.pozycje.count() for d in obj.dzialy.all())


class KosztorysSerializer(serializers.ModelSerializer):
    dzialy = KosztorysdzDzialSerializer(many=True, read_only=True)
    wartosc_total = serializers.SerializerMethodField()

    class Meta:
        model = Kosztorys
        fields = [
            "id", "company_id", "budowa_id", "nazwa", "opis", "status",
            "ai_prompt", "created_at", "updated_at", "created_by",
            "dzialy", "wartosc_total",
        ]
        read_only_fields = ["company_id", "created_by", "created_at", "updated_at"]

    def get_wartosc_total(self, obj) -> Decimal:
        total = Decimal("0")
        for dzial in obj.dzialy.all():
            for p in dzial.pozycje.all():
                total += p.wartosc
        return total


class KosztorysWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Kosztorys
        fields = ["budowa_id", "nazwa", "opis", "status", "ai_prompt"]
