from rest_framework import serializers
from .models import Material, HistoriaCeny, PozycjaZamowienia, KategoriaMaterialu


class HistoriaCenySerializer(serializers.ModelSerializer):
    class Meta:
        model = HistoriaCeny
        fields = ['id', 'cena_netto', 'data', 'zrodlo', 'uwagi']


class MaterialListSerializer(serializers.ModelSerializer):
    cena_brutto = serializers.SerializerMethodField()
    trend = serializers.SerializerMethodField()

    class Meta:
        model = Material
        fields = [
            'id', 'nazwa', 'jednostka', 'kategoria', 'producent', 'symbol',
            'vat', 'cena_netto', 'cena_brutto', 'cena_updated_at', 'trend',
        ]

    def get_cena_brutto(self, obj):
        b = obj.cena_brutto
        return float(b) if b is not None else None

    def get_trend(self, obj):
        """
        Zwraca trend na podstawie ostatnich 3 wpisów historii cen.
        'rosnacy' | 'spadajacy' | 'stabilny' | null
        """
        historia = list(
            obj.historia_cen.order_by('-data').values_list('cena_netto', flat=True)[:3]
        )
        if len(historia) < 2:
            return None
        historia.reverse()  # chronologicznie
        if historia[-1] > historia[0]:
            return 'rosnacy'
        if historia[-1] < historia[0]:
            return 'spadajacy'
        return 'stabilny'


class MaterialDetailSerializer(MaterialListSerializer):
    historia_cen = HistoriaCenySerializer(many=True, read_only=True)

    class Meta(MaterialListSerializer.Meta):
        fields = MaterialListSerializer.Meta.fields + ['opis', 'historia_cen', 'created_at']


class MaterialWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Material
        fields = [
            'nazwa', 'opis', 'jednostka', 'kategoria',
            'producent', 'symbol', 'vat', 'cena_netto',
        ]


class PozycjaZamowieniaSerializer(serializers.ModelSerializer):
    material = MaterialListSerializer(read_only=True)
    material_id = serializers.PrimaryKeyRelatedField(
        queryset=Material.objects.all(), source='material', write_only=True
    )
    wartosc_netto = serializers.SerializerMethodField()
    brakuje = serializers.SerializerMethodField()

    class Meta:
        model = PozycjaZamowienia
        fields = [
            'id', 'material', 'material_id',
            'budowa_id', 'kosztorys_id', 'etap_id',
            'ilosc', 'ilosc_dostarczona', 'cena_netto_zakupu',
            'status', 'uwagi', 'data_potrzeby', 'data_zamowienia', 'data_dostawy',
            'wartosc_netto', 'brakuje',
            'created_at', 'updated_at',
        ]

    def get_wartosc_netto(self, obj):
        w = obj.wartosc_netto
        return float(w) if w is not None else None

    def get_brakuje(self, obj):
        return float(obj.brakuje)
