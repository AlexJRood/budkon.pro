from rest_framework import serializers
from .models import Kontrahent, PowiazaniePodwykonawcy


class KontrahentSerializer(serializers.ModelSerializer):
    display_name = serializers.CharField(read_only=True)
    pelne_imie = serializers.CharField(read_only=True)
    avatar_url = serializers.SerializerMethodField()

    class Meta:
        model = Kontrahent
        fields = [
            "id",
            "imie",
            "nazwisko",
            "firma",
            "display_name",
            "pelne_imie",
            "email",
            "telefon",
            "nip",
            "adres",
            "branza",
            "uwagi",
            "avatar_url",
            "created_at",
        ]
        read_only_fields = ["display_name", "pelne_imie", "avatar_url", "created_at"]

    def get_avatar_url(self, obj):
        request = self.context.get("request")
        if obj.avatar and request:
            return request.build_absolute_uri(obj.avatar.url)
        return None


class KontrahentSearchSerializer(serializers.ModelSerializer):
    """Lekki serializer do pola wyszukiwania (picker)."""

    display_name = serializers.CharField(read_only=True)
    avatar_url = serializers.SerializerMethodField()

    class Meta:
        model = Kontrahent
        fields = [
            "id",
            "display_name",
            "firma",
            "imie",
            "nazwisko",
            "telefon",
            "email",
            "branza",
            "avatar_url",
        ]

    def get_avatar_url(self, obj):
        request = self.context.get("request")
        if obj.avatar and request:
            return request.build_absolute_uri(obj.avatar.url)
        return None


class PowiazanieListSerializer(serializers.ModelSerializer):
    """Powiązanie + zagnieżdżone dane kontrahenta."""

    kontrahent = KontrahentSerializer(read_only=True)
    etap_nazwa = serializers.CharField(source="etap.nazwa", read_only=True, default=None)

    class Meta:
        model = PowiazaniePodwykonawcy
        fields = [
            "id",
            "kontrahent",
            "etap",
            "etap_nazwa",
            "rola",
            "status",
            "wartosc_umowy",
            "data_od",
            "data_do",
            "uwagi",
        ]


class PowiazanieWriteSerializer(serializers.ModelSerializer):
    kontrahent_id = serializers.PrimaryKeyRelatedField(
        source="kontrahent",
        queryset=Kontrahent.objects.all(),
    )

    class Meta:
        model = PowiazaniePodwykonawcy
        fields = [
            "kontrahent_id",
            "etap",
            "rola",
            "status",
            "wartosc_umowy",
            "data_od",
            "data_do",
            "uwagi",
        ]
