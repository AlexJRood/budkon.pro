from rest_framework import serializers
from .models import Faktura, StatusFaktury


class FakturaListSerializer(serializers.ModelSerializer):
    budowa_nazwa = serializers.CharField(source='budowa.nazwa', read_only=True)
    jest_przeterminowana = serializers.BooleanField(read_only=True)

    class Meta:
        model = Faktura
        fields = [
            'id', 'numer', 'typ', 'status',
            'nabywca_nazwa', 'budowa_id', 'budowa_nazwa',
            'data_wystawienia', 'termin_platnosci',
            'wartosc_netto', 'wartosc_vat', 'wartosc_brutto', 'stawka_vat',
            'jest_przeterminowana', 'created_at',
        ]


class FakturaDetailSerializer(serializers.ModelSerializer):
    budowa_nazwa = serializers.CharField(source='budowa.nazwa', read_only=True)
    jest_przeterminowana = serializers.BooleanField(read_only=True)

    class Meta:
        model = Faktura
        fields = '__all__'


class FakturaWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Faktura
        fields = [
            'typ', 'budowa_id', 'oferta_id',
            'wystawca_nazwa', 'wystawca_nip', 'wystawca_adres', 'wystawca_konto',
            'nabywca_nazwa', 'nabywca_nip', 'nabywca_adres',
            'data_wystawienia', 'data_sprzedazy', 'termin_platnosci',
            'metoda_platnosci', 'pozycje', 'stawka_vat', 'uwagi',
        ]
