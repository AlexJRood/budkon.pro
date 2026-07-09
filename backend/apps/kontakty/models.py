from django.db import models


class Kontrahent(models.Model):
    """
    Lokalny kontakt w budkon.pro — podwykonawca, dostawca, projektant itd.
    Nie duplikuje danych Hously.pro CRM — to oddzielna baza kontaktów budowlanych.
    """

    company_id = models.IntegerField(db_index=True)
    imie = models.CharField(max_length=100, blank=True)
    nazwisko = models.CharField(max_length=100, blank=True)
    firma = models.CharField(max_length=255, blank=True)
    email = models.EmailField(blank=True)
    telefon = models.CharField(max_length=30, blank=True)
    nip = models.CharField(max_length=20, blank=True, db_index=True)
    adres = models.CharField(max_length=500, blank=True)
    branza = models.CharField(
        max_length=40,
        blank=True,
        choices=[
            ("elektryczna", "Elektryczna"),
            ("hydrauliczna", "Hydrauliczna / wod-kan"),
            ("budowlana", "Budowlana / murarstwo"),
            ("fundamenty", "Fundamenty / ziemna"),
            ("dach", "Dach / pokrycia"),
            ("stolarska", "Stolarka / okna-drzwi"),
            ("wykanczanie", "Wykańczanie / tynki"),
            ("podlogi", "Podłogi"),
            ("elewacja", "Elewacja / ocieplenie"),
            ("instalacje_co", "Instalacje CO / gaz"),
            ("wentylacja", "Wentylacja / klimat."),
            ("geodezja", "Geodezja"),
            ("projekt", "Projektant / architekt"),
            ("kierownik", "Kierownik budowy"),
            ("inspektor", "Inspektor nadzoru"),
            ("transport", "Transport / logistyka"),
            ("inna", "Inna"),
        ],
    )
    uwagi = models.TextField(blank=True)
    avatar = models.ImageField(
        upload_to="kontrakty/avatary/", null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["nazwisko", "imie", "firma"]
        verbose_name_plural = "kontrahenci"

    def __str__(self):
        if self.firma:
            return f"{self.firma} ({self.pelne_imie})" if self.pelne_imie else self.firma
        return self.pelne_imie or f"Kontrahent #{self.pk}"

    @property
    def pelne_imie(self) -> str:
        return " ".join(filter(None, [self.imie, self.nazwisko]))

    @property
    def display_name(self) -> str:
        return self.firma or self.pelne_imie or f"Kontrahent #{self.pk}"


class PowiazaniePodwykonawcy(models.Model):
    """
    Powiązanie kontrahenta z budową — bez duplikowania danych kontaktu.
    """

    company_id = models.IntegerField(db_index=True)
    kontrahent = models.ForeignKey(
        Kontrahent, on_delete=models.PROTECT, related_name="powiazania"
    )
    budowa = models.ForeignKey(
        "budowa.Budowa", on_delete=models.CASCADE, related_name="podwykonawcy"
    )
    etap = models.ForeignKey(
        "budowa.EtapBudowy",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="podwykonawcy",
    )
    rola = models.CharField(max_length=255, blank=True)  # rola na tej konkretnej budowie
    status = models.CharField(
        max_length=20,
        choices=[
            ("zaproszony", "Zaproszony"),
            ("aktywny", "Aktywny"),
            ("zakonczony", "Zakończony"),
            ("odrzucony", "Odrzucony"),
        ],
        default="aktywny",
    )
    wartosc_umowy = models.DecimalField(
        max_digits=14, decimal_places=2, null=True, blank=True
    )
    data_od = models.DateField(null=True, blank=True)
    data_do = models.DateField(null=True, blank=True)
    uwagi = models.TextField(blank=True)

    class Meta:
        unique_together = ("kontrahent", "budowa")
        ordering = ["kontrahent__nazwisko", "kontrahent__firma"]
        verbose_name_plural = "powiązania podwykonawców"

    def __str__(self):
        return f"{self.kontrahent} @ {self.budowa}"
