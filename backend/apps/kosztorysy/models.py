from django.db import models


class KnrKatalog(models.Model):
    """Katalog Nakładów Rzeczowych — np. KNR 2-02, KNNR 4."""

    kod = models.CharField(max_length=20, unique=True)  # "KNR 2-02"
    nazwa = models.CharField(max_length=255)
    opis = models.TextField(blank=True)

    class Meta:
        verbose_name_plural = "katalogi KNR"

    def __str__(self):
        return f"{self.kod} — {self.nazwa}"


class KnrPozycja(models.Model):
    """Pojedyncza pozycja KNR z nakładami."""

    katalog = models.ForeignKey(
        KnrKatalog, on_delete=models.CASCADE, related_name="pozycje"
    )
    numer = models.CharField(max_length=30)  # "0201-01"
    opis = models.TextField()
    jednostka = models.CharField(max_length=20)  # "m2", "m3", "szt"
    naklad_r = models.DecimalField(
        max_digits=10, decimal_places=4, default=0
    )  # rbh/jednostkę
    naklad_m = models.DecimalField(
        max_digits=10, decimal_places=4, default=0
    )  # materiał
    naklad_s = models.DecimalField(
        max_digits=10, decimal_places=4, default=0
    )  # sprzęt rbh

    class Meta:
        unique_together = ("katalog", "numer")
        verbose_name_plural = "pozycje KNR"

    def __str__(self):
        return f"{self.katalog.kod} {self.numer}: {self.opis[:60]}"


class Kosztorys(models.Model):
    """Kosztorys powiązany z budową."""

    company_id = models.IntegerField(db_index=True)  # multi-tenancy
    budowa_id = models.IntegerField(null=True, blank=True, db_index=True)
    nazwa = models.CharField(max_length=255)
    opis = models.TextField(blank=True)
    status = models.CharField(
        max_length=20,
        choices=[
            ("roboczy", "Roboczy"),
            ("oferta", "Oferta"),
            ("zatwierdzony", "Zatwierdzony"),
        ],
        default="roboczy",
    )
    ai_prompt = models.TextField(blank=True)  # oryginalny opis użytkownika → AI
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.IntegerField()

    class Meta:
        verbose_name_plural = "kosztorysy"

    def __str__(self):
        return self.nazwa


class KosztorysdzDzial(models.Model):
    """Dział kosztorysu — np. 'Roboty ziemne', 'Murowe'."""

    kosztorys = models.ForeignKey(
        Kosztorys, on_delete=models.CASCADE, related_name="dzialy"
    )
    nazwa = models.CharField(max_length=255)
    kolejnosc = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["kolejnosc"]


class KosztorysPozycja(models.Model):
    """Pozycja kosztorysowa — powiązana z KNR lub własna."""

    dzial = models.ForeignKey(
        KosztorysdzDzial, on_delete=models.CASCADE, related_name="pozycje"
    )
    knr_pozycja = models.ForeignKey(
        KnrPozycja, null=True, blank=True, on_delete=models.SET_NULL
    )
    opis = models.TextField()
    jednostka = models.CharField(max_length=20)
    ilosc = models.DecimalField(max_digits=12, decimal_places=3)
    cena_jednostkowa = models.DecimalField(max_digits=12, decimal_places=2)
    kolejnosc = models.PositiveIntegerField(default=0)

    # Feedback loop: czy użytkownik korygował wartość AI
    ai_suggested_price = models.DecimalField(
        max_digits=12, decimal_places=2, null=True, blank=True
    )
    ai_suggested_qty = models.DecimalField(
        max_digits=12, decimal_places=3, null=True, blank=True
    )

    class Meta:
        ordering = ["kolejnosc"]

    @property
    def wartosc(self):
        return self.ilosc * self.cena_jednostkowa
