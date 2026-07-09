from django.db import models


class PogodaTyp(models.TextChoices):
    SLONECZNIE = "slonecznie", "Słonecznie"
    CZESCIOWE_ZACHMURZENIE = "czesciowe_zachmurzenie", "Częściowe zachmurzenie"
    POCHMURNO = "pochmurno", "Pochmurno"
    DESZCZ = "deszcz", "Deszcz"
    BURZA = "burza", "Burza"
    SNIEG = "snieg", "Śnieg"
    WIATR = "wiatr", "Silny wiatr"
    MGLA = "mgla", "Mgła"
    MRÓZ = "mroz", "Mróz"


class WpisDziennika(models.Model):
    """Dzienny wpis do dziennika budowy."""

    company_id = models.IntegerField(db_index=True)
    budowa = models.ForeignKey(
        "budowa.Budowa",
        on_delete=models.CASCADE,
        related_name="wpisy_dziennika",
    )
    etap = models.ForeignKey(
        "budowa.EtapBudowy",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="wpisy_dziennika",
    )
    data = models.DateField()
    opis = models.TextField(blank=True)
    uwagi = models.TextField(blank=True)

    # Pogoda — auto-uzupełniana przez weather service
    pogoda = models.CharField(
        max_length=30, choices=PogodaTyp.choices, blank=True
    )
    temperatura = models.FloatField(null=True, blank=True)  # °C
    predkosc_wiatru = models.FloatField(null=True, blank=True)  # km/h
    opady = models.FloatField(null=True, blank=True)  # mm
    pogoda_auto = models.BooleanField(default=False)  # czy pobrana automatycznie

    # Praca
    godziny_pracy = models.FloatField(default=0)
    liczba_pracownikow = models.IntegerField(default=0)

    autor_id = models.IntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        app_label = "dziennik"
        unique_together = [("budowa", "data")]
        ordering = ["-data"]
        indexes = [
            models.Index(fields=["company_id", "budowa", "data"]),
        ]

    def __str__(self):
        return f"Dziennik {self.budowa_id} — {self.data}"


class ObecnoscNaBudowie(models.Model):
    """Kto był na budowie danego dnia."""

    wpis = models.ForeignKey(
        WpisDziennika,
        on_delete=models.CASCADE,
        related_name="obecnosci",
    )
    # Luźne powiązanie z kontaktem — contact_id z CRM (opcjonalne)
    contact_id = models.IntegerField(null=True, blank=True)
    imie_nazwisko = models.CharField(max_length=150)
    rola = models.CharField(max_length=100, blank=True)  # murarz, kierownik, etc.
    godziny = models.FloatField(default=8)

    class Meta:
        app_label = "dziennik"

    def __str__(self):
        return f"{self.imie_nazwisko} @ {self.wpis.data}"


class ZdjecieDziennika(models.Model):
    """Zdjęcie z budowy dołączone do wpisu dziennika."""

    wpis = models.ForeignKey(
        WpisDziennika,
        on_delete=models.CASCADE,
        related_name="zdjecia",
    )
    plik = models.ImageField(upload_to="dziennik/%Y/%m/")
    opis = models.CharField(max_length=300, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        app_label = "dziennik"
        ordering = ["created_at"]

    def __str__(self):
        return f"Zdjęcie do {self.wpis}"
