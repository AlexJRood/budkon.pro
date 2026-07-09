from django.db import models
from django.utils import timezone


class KategoriaMaterialu(models.TextChoices):
    BETON = 'beton', 'Beton i kruszywa'
    STAL = 'stal', 'Stal i metale'
    DREWNO = 'drewno', 'Drewno i stolarka'
    CERAMIKA = 'ceramika', 'Ceramika i bloki'
    IZOLACJA = 'izolacja', 'Izolacja i hydroizolacja'
    INSTALACJE = 'instalacje', 'Instalacje wod-kan'
    ELEKTRYKA = 'elektryka', 'Elektryka'
    ELEWACJA = 'elewacja', 'Elewacja i tynki'
    POKRYCIE = 'pokrycie', 'Pokrycie dachowe'
    WYKONCZENIE = 'wykonczenie', 'Wykończenie'
    CHEMIA = 'chemia', 'Chemia budowlana'
    NARZEDZIA = 'narzedzia', 'Narzędzia i sprzęt'
    INNE = 'inne', 'Inne'


class Material(models.Model):
    company_id = models.IntegerField(db_index=True)
    nazwa = models.CharField(max_length=255)
    opis = models.TextField(blank=True)
    jednostka = models.CharField(max_length=20, default='szt')  # m², kg, mb, szt, m³ ...
    kategoria = models.CharField(
        max_length=20,
        choices=KategoriaMaterialu.choices,
        default=KategoriaMaterialu.INNE,
    )
    producent = models.CharField(max_length=100, blank=True)
    symbol = models.CharField(max_length=100, blank=True)  # indeks katalogowy
    vat = models.PositiveSmallIntegerField(default=23)

    # Aktualna cena — denormalizacja, aktualizowana przy każdym nowym wpisie historii
    cena_netto = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    cena_updated_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['kategoria', 'nazwa']

    def __str__(self):
        return f'{self.nazwa} [{self.jednostka}]'

    @property
    def cena_brutto(self):
        if self.cena_netto is None:
            return None
        return self.cena_netto * (1 + self.vat / 100)

    def aktualizuj_cene(self, cena_netto, zrodlo='reczne'):
        """Dodaje wpis historii i aktualizuje bieżącą cenę."""
        HistoriaCeny.objects.create(
            material=self,
            cena_netto=cena_netto,
            zrodlo=zrodlo,
        )
        self.cena_netto = cena_netto
        self.cena_updated_at = timezone.now()
        self.save(update_fields=['cena_netto', 'cena_updated_at'])


class ZrodlaCeny(models.TextChoices):
    RECZNE = 'reczne', 'Ręczne'
    IMPORT = 'import', 'Import CSV'
    KOSZTORYS = 'kosztorys', 'Z kosztorysu'
    ZAMOWIENIE = 'zamowienie', 'Z zamówienia'


class HistoriaCeny(models.Model):
    material = models.ForeignKey(
        Material,
        on_delete=models.CASCADE,
        related_name='historia_cen',
    )
    cena_netto = models.DecimalField(max_digits=12, decimal_places=2)
    data = models.DateField(default=timezone.now)
    zrodlo = models.CharField(
        max_length=20,
        choices=ZrodlaCeny.choices,
        default=ZrodlaCeny.RECZNE,
    )
    uwagi = models.CharField(max_length=255, blank=True)

    class Meta:
        ordering = ['data']

    def __str__(self):
        return f'{self.material.nazwa} {self.cena_netto} PLN ({self.data})'


class StatusPozycji(models.TextChoices):
    DO_ZAMOWIENIA = 'do_zamowienia', 'Do zamówienia'
    ZAMOWIONE = 'zamowione', 'Zamówione'
    W_DOSTAWIE = 'w_dostawie', 'W dostawie'
    DOSTARCZONE = 'dostarczone', 'Dostarczone'
    ZWROCONE = 'zwrocone', 'Zwrócone'


class PozycjaZamowienia(models.Model):
    """Pojedyncza linia materiałowa powiązana z budową i opcjonalnie kosztorysem."""
    company_id = models.IntegerField(db_index=True)
    material = models.ForeignKey(
        Material,
        on_delete=models.PROTECT,
        related_name='pozycje',
    )
    budowa_id = models.IntegerField(db_index=True)
    kosztorys_id = models.IntegerField(null=True, blank=True)
    etap_id = models.IntegerField(null=True, blank=True)

    ilosc = models.DecimalField(max_digits=12, decimal_places=3)
    ilosc_dostarczona = models.DecimalField(
        max_digits=12, decimal_places=3, default=0
    )
    cena_netto_zakupu = models.DecimalField(
        max_digits=12, decimal_places=2, null=True, blank=True
    )
    status = models.CharField(
        max_length=20,
        choices=StatusPozycji.choices,
        default=StatusPozycji.DO_ZAMOWIENIA,
    )
    uwagi = models.CharField(max_length=500, blank=True)
    data_potrzeby = models.DateField(null=True, blank=True)
    data_zamowienia = models.DateField(null=True, blank=True)
    data_dostawy = models.DateField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['status', 'data_potrzeby']

    def __str__(self):
        return f'{self.material.nazwa} × {self.ilosc} [{self.status}]'

    @property
    def wartosc_netto(self):
        cena = self.cena_netto_zakupu or self.material.cena_netto
        if cena is None:
            return None
        return float(cena) * float(self.ilosc)

    @property
    def brakuje(self):
        return max(0, float(self.ilosc) - float(self.ilosc_dostarczona))
