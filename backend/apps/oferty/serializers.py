from rest_framework import serializers
from .models import Oferta, HistoriaStatusuOferty


class HistoriaStatusuSerializer(serializers.ModelSerializer):
    class Meta:
        model = HistoriaStatusuOferty
        fields = ['id', 'status', 'data', 'uwagi']


class OfertyListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Oferta
        fields = [
            'id', 'numer', 'tytul', 'klient_nazwa',
            'wartosc_netto', 'wartosc_brutto', 'status',
            'data_wystawienia', 'wazna_do',
            'budowa_id', 'kosztorys_id',
            'created_at',
        ]


class OfertyDetailSerializer(serializers.ModelSerializer):
    historia_statusu = HistoriaStatusuSerializer(many=True, read_only=True)
    has_pdf = serializers.SerializerMethodField()

    class Meta:
        model = Oferta
        fields = '__all__'

    def get_has_pdf(self, obj):
        return bool(obj.pdf_url)


class OfertyWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Oferta
        exclude = ['pdf_url', 'created_at', 'updated_at']
