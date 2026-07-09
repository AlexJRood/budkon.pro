from django.db import models
from django.utils import timezone


class Specjalizacja(models.TextChoices):
    """Mapuje na KNR kategorie — AI używa tego do doboru pracowników."""
    MURARZ = 'murarz', 'Murarz'
    ZBROJARZ = 'zbrojarz', 'Zbrojarz / betoniar'
    CIESLA = 'ciesla', 'Cieśla'
    DEKARZ = 'dekarz', 'Dekarz'
    TYNKARZ = 'tynkarz', 'Tynkarz / glazurnik'
    INSTALATOR_WOD_KAN = 'instalator_wod_kan', 'Instalator wod-kan'
    ELEKTRYK = 'elektryk', 'Elektryk'
    SPAWACZ = 'spawacz', 'Spawacz'
    OPERATOR_SPRZETU = 'operator', 'Operator sprzętu'
    KIEROWNIK = 'kierownik', 'Kierownik budowy'
    GEODETA = 'geodeta', 'Geodeta'
    POMOCNIK = 'pomocnik', 'Pomocnik budowlany'
    INNE = 'inne', 'Inne'


class PoziomDoswiadczenia(models.TextChoices):
    UCZEN = 'uczen', 'Uczeń / staż'
    JUNIOR = 'junior', 'Junior (1-3 lata)'
    MID = 'mid', 'Samodzielny (3-8 lat)'
    SENIOR = 'senior', 'Senior (8-15 lat)'
    EKSPERT = 'ekspert', 'Ekspert (15+ lat)'


# Mapowanie specjalizacji → mnożnik stawki względem podstawy
MNOZNIK_STAWKI = {
    PoziomDoswiadczenia.UCZEN: 0.6,
    PoziomDoswiadczenia.JUNIOR: 0.8,
    PoziomDoswiadczenia.MID: 1.0,
    PoziomDoswiadczenia.SENIOR: 1.3,
    PoziomDoswiadczenia.EKSPERT: 1.6,
}


class Pracownik(models.Model):
    company_id = models.IntegerField(db_index=True)
    imie = models.CharField(max_length=100)
    nazwisko = models.CharField(max_length=100)
    telefon = models.CharField(max_length=30, blank=True)
    email = models.EmailField(blank=True)
    pesel = models.CharField(max_length=11, blank=True)
    numer_umowy = models.CharField(max_length=50, blank=True)
    typ_umowy = models.CharField(
        max_length=20,
        choices=[
            ('umowa_o_prace', 'Umowa o pracę'),
            ('umowa_zlecenie', 'Umowa zlecenie'),
            ('b2b', 'B2B'),
            ('dzieło', 'Umowa o dzieło'),
        ],
        default='umowa_zlecenie',
    )
    # Główna specjalizacja (skrót — pełna lista w UmiejetnosciPracownika)
    glowna_specjalizacja = models.CharField(
        max_length=30,
        choices=Specjalizacja.choices,
        default=Specjalizacja.POMOCNIK,
    )
    aktywny = models.BooleanField(default=True)
    data_zatrudnienia = models.DateField(null=True, blank=True)
    uwagi = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['nazwisko', 'imie']

    def __str__(self):
        return f'{self.imie} {self.nazwisko}'

    @property
    def pelne_imie(self):
        return f'{self.imie} {self.nazwisko}'

    @property
    def aktualna_stawka(self):
        s = self.stawki.filter(
            data_od__lte=timezone.now().date()
        ).order_by('-data_od').first()
        return float(s.stawka_godz) if s else None


class UmiejetnoscPracownika(models.Model):
    """
    Macierz umiejętności — pracownik × specjalizacja × poziom.
    Jeden pracownik może mieć wiele specjalizacji.
    """
    pracownik = models.ForeignKey(
        Pracownik, on_delete=models.CASCADE, related_name='umiejetnosci'
    )
    specjalizacja = models.CharField(
        max_length=30, choices=Specjalizacja.choices
    )
    poziom = models.CharField(
        max_length=20,
        choices=PoziomDoswiadczenia.choices,
        default=PoziomDoswiadczenia.MID,
    )
    lata_doswiadczenia = models.PositiveSmallIntegerField(default=0)

    # Certyfikaty / uprawnienia
    certyfikat = models.CharField(max_length=255, blank=True)
    numer_certyfikatu = models.CharField(max_length=100, blank=True)
    certyfikat_wazny_do = models.DateField(null=True, blank=True)

    # Stawka dla tej konkretnej umiejętności (może różnić się od globalnej)
    stawka_specjalizacji = models.DecimalField(
        max_digits=8, decimal_places=2, null=True, blank=True
    )

    uwagi = models.TextField(blank=True)

    class Meta:
        unique_together = ('pracownik', 'specjalizacja')
        ordering = ['specjalizacja']

    def __str__(self):
        return f'{self.pracownik} — {self.get_specjalizacja_display()} ({self.get_poziom_display()})'

    @property
    def certyfikat_wazny(self):
        if self.certyfikat_wazny_do is None:
            return True
        return self.certyfikat_wazny_do >= timezone.now().date()

    @property
    def mnoznik(self):
        return MNOZNIK_STAWKI.get(self.poziom, 1.0)


class HistoriaStawki(models.Model):
    """Historia stawek godzinowych — do kosztorysowania."""
    pracownik = models.ForeignKey(
        Pracownik, on_delete=models.CASCADE, related_name='stawki'
    )
    stawka_godz = models.DecimalField(max_digits=8, decimal_places=2)
    waluta = models.CharField(max_length=5, default='PLN')
    data_od = models.DateField()
    uwagi = models.CharField(max_length=255, blank=True)

    class Meta:
        ordering = ['-data_od']

    def __str__(self):
        return f'{self.pracownik} {self.stawka_godz} {self.waluta}/h od {self.data_od}'


class PracownikNaBudowie(models.Model):
    """Przypisanie pracownika do konkretnej budowy."""
    company_id = models.IntegerField(db_index=True)
    pracownik = models.ForeignKey(
        Pracownik, on_delete=models.CASCADE, related_name='budowy'
    )
    budowa_id = models.IntegerField(db_index=True)
    etap_id = models.IntegerField(null=True, blank=True)
    rola_na_budowie = models.CharField(max_length=100, blank=True)
    data_od = models.DateField(null=True, blank=True)
    data_do = models.DateField(null=True, blank=True)
    aktywny = models.BooleanField(default=True)

    class Meta:
        unique_together = ('pracownik', 'budowa_id')

    def __str__(self):
        return f'{self.pracownik} @ budowa {self.budowa_id}'
