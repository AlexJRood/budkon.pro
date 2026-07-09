from rest_framework import serializers

from .models import ObecnoscNaBudowie, WpisDziennika, ZdjecieDziennika


class ObecnoscSerializer(serializers.ModelSerializer):
    class Meta:
        model = ObecnoscNaBudowie
        fields = ["id", "contact_id", "imie_nazwisko", "rola", "godziny"]


class ZdjecieSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = ZdjecieDziennika
        fields = ["id", "url", "opis", "created_at"]

    def get_url(self, obj):
        request = self.context.get("request")
        if obj.plik and request:
            return request.build_absolute_uri(obj.plik.url)
        return obj.plik.url if obj.plik else None


class WpisListSerializer(serializers.ModelSerializer):
    etap_nazwa = serializers.CharField(source="etap.nazwa", read_only=True)
    zdjecia_count = serializers.IntegerField(
        source="zdjecia.count", read_only=True
    )

    class Meta:
        model = WpisDziennika
        fields = [
            "id",
            "data",
            "etap_nazwa",
            "pogoda",
            "temperatura",
            "predkosc_wiatru",
            "opady",
            "pogoda_auto",
            "godziny_pracy",
            "liczba_pracownikow",
            "opis",
            "zdjecia_count",
            "created_at",
        ]


class WpisDetailSerializer(serializers.ModelSerializer):
    etap_nazwa = serializers.CharField(source="etap.nazwa", read_only=True)
    obecnosci = ObecnoscSerializer(many=True, read_only=True)
    zdjecia = ZdjecieSerializer(many=True, read_only=True)

    class Meta:
        model = WpisDziennika
        fields = [
            "id",
            "budowa_id",
            "etap_id",
            "etap_nazwa",
            "data",
            "opis",
            "uwagi",
            "pogoda",
            "temperatura",
            "predkosc_wiatru",
            "opady",
            "pogoda_auto",
            "godziny_pracy",
            "liczba_pracownikow",
            "obecnosci",
            "zdjecia",
            "autor_id",
            "created_at",
            "updated_at",
        ]


class WpisWriteSerializer(serializers.ModelSerializer):
    obecnosci = ObecnoscSerializer(many=True, required=False)

    class Meta:
        model = WpisDziennika
        fields = [
            "budowa_id",
            "etap_id",
            "data",
            "opis",
            "uwagi",
            "pogoda",
            "temperatura",
            "predkosc_wiatru",
            "opady",
            "godziny_pracy",
            "liczba_pracownikow",
            "obecnosci",
        ]

    def create(self, validated_data):
        obecnosci_data = validated_data.pop("obecnosci", [])
        wpis = WpisDziennika.objects.create(**validated_data)
        for o in obecnosci_data:
            ObecnoscNaBudowie.objects.create(wpis=wpis, **o)
        return wpis

    def update(self, instance, validated_data):
        obecnosci_data = validated_data.pop("obecnosci", None)
        for attr, val in validated_data.items():
            setattr(instance, attr, val)
        instance.save()
        if obecnosci_data is not None:
            instance.obecnosci.all().delete()
            for o in obecnosci_data:
                ObecnoscNaBudowie.objects.create(wpis=instance, **o)
        return instance


class AutoUzupelnijResponseSerializer(serializers.Serializer):
    pogoda = serializers.CharField()
    temperatura = serializers.FloatField()
    predkosc_wiatru = serializers.FloatField()
    opady = serializers.FloatField()
    etap_id = serializers.IntegerField(allow_null=True)
    etap_nazwa = serializers.CharField(allow_null=True)
    liczba_pracownikow_poprzedni = serializers.IntegerField()
