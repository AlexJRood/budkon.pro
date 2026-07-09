from django.utils import timezone
from rest_framework import serializers
from .models import Pracownik, UmiejetnoscPracownika, HistoriaStawki, PracownikNaBudowie


class UmiejetnoscSerializer(serializers.ModelSerializer):
    specjalizacja_label = serializers.CharField(
        source='get_specjalizacja_display', read_only=True
    )
    poziom_label = serializers.CharField(
        source='get_poziom_display', read_only=True
    )
    certyfikat_wazny = serializers.BooleanField(read_only=True)
    mnoznik = serializers.FloatField(read_only=True)

    class Meta:
        model = UmiejetnoscPracownika
        fields = [
            'id', 'specjalizacja', 'specjalizacja_label',
            'poziom', 'poziom_label', 'lata_doswiadczenia',
            'certyfikat', 'numer_certyfikatu', 'certyfikat_wazny_do',
            'certyfikat_wazny', 'stawka_specjalizacji', 'mnoznik', 'uwagi',
        ]


class HistoriaStawkiSerializer(serializers.ModelSerializer):
    class Meta:
        model = HistoriaStawki
        fields = ['id', 'stawka_godz', 'waluta', 'data_od', 'uwagi']


class PracownikListSerializer(serializers.ModelSerializer):
    pelne_imie = serializers.CharField(read_only=True)
    aktualna_stawka = serializers.FloatField(read_only=True)
    specjalizacje = serializers.SerializerMethodField()
    glowna_specjalizacja_label = serializers.CharField(
        source='get_glowna_specjalizacja_display', read_only=True
    )

    class Meta:
        model = Pracownik
        fields = [
            'id', 'imie', 'nazwisko', 'pelne_imie',
            'telefon', 'email',
            'glowna_specjalizacja', 'glowna_specjalizacja_label',
            'aktywny', 'typ_umowy',
            'aktualna_stawka', 'specjalizacje',
        ]

    def get_specjalizacje(self, obj):
        return [
            {
                'specjalizacja': u.specjalizacja,
                'label': u.get_specjalizacja_display(),
                'poziom': u.poziom,
                'poziom_label': u.get_poziom_display(),
                'lata': u.lata_doswiadczenia,
                'certyfikat_wazny': u.certyfikat_wazny,
            }
            for u in obj.umiejetnosci.all()
        ]


class PracownikDetailSerializer(PracownikListSerializer):
    umiejetnosci = UmiejetnoscSerializer(many=True, read_only=True)
    historia_stawek = HistoriaStawkiSerializer(
        source='stawki', many=True, read_only=True
    )

    class Meta(PracownikListSerializer.Meta):
        fields = PracownikListSerializer.Meta.fields + [
            'pesel', 'numer_umowy', 'data_zatrudnienia',
            'uwagi', 'umiejetnosci', 'historia_stawek', 'created_at',
        ]


class PracownikWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Pracownik
        fields = [
            'imie', 'nazwisko', 'telefon', 'email', 'pesel',
            'numer_umowy', 'typ_umowy', 'glowna_specjalizacja',
            'aktywny', 'data_zatrudnienia', 'uwagi',
        ]


class PracownikNaBudowieSerializer(serializers.ModelSerializer):
    pracownik = PracownikListSerializer(read_only=True)
    pracownik_id = serializers.PrimaryKeyRelatedField(
        queryset=Pracownik.objects.all(), source='pracownik', write_only=True
    )

    class Meta:
        model = PracownikNaBudowie
        fields = [
            'id', 'pracownik', 'pracownik_id',
            'budowa_id', 'etap_id', 'rola_na_budowie',
            'data_od', 'data_do', 'aktywny',
        ]
