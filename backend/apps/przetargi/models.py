from django.db import models


class StatusPrzetargu(models.TextChoices):
    NOWY = "nowy", "Nowy"
    ANALIZOWANY = "analizowany", "Analizowany"
    KOSZTORYS_GOTOWY = "kosztorys_gotowy", "Kosztorys gotowy"
    ZLOZONY = "zlozony", "Złożony"
    WYGRANY = "wygrany", "Wygrany"
    PRZEGRANY = "przegrany", "Przegrany"
    POMINIETY = "pominiety", "Pominięty"


class ZrodloPrzetargu(models.TextChoices):
    BZP = "bzp", "BZP (ezamówienia.gov.pl)"
    TED = "ted", "TED (europa.eu)"
    MANUAL = "manual", "Ręcznie dodany"


class Przetarg(models.Model):
    company_id = models.IntegerField(db_index=True)

    # Dane z zewnętrznego źródła
    tytul = models.CharField(max_length=500)
    zamawiajacy = models.CharField(max_length=300)
    opis = models.TextField(blank=True)
    wartosc_szacunkowa = models.DecimalField(
        max_digits=14, decimal_places=2, null=True, blank=True
    )
    waluta = models.CharField(max_length=3, default="PLN")
    termin_skladania = models.DateTimeField(null=True, blank=True)
    termin_realizacji = models.DateField(null=True, blank=True)
    lokalizacja = models.CharField(max_length=200, blank=True)
    cpv_kody = models.JSONField(default=list)  # ["45000000-7", ...]

    # Źródło
    zrodlo = models.CharField(
        max_length=20, choices=ZrodloPrzetargu.choices, default=ZrodloPrzetargu.BZP
    )
    zrodlo_id = models.CharField(max_length=100, blank=True)  # external ID
    zrodlo_url = models.URLField(max_length=500, blank=True)
    raw_data = models.JSONField(default=dict)  # pełna odpowiedź z API

    # Status w firmie
    status = models.CharField(
        max_length=20,
        choices=StatusPrzetargu.choices,
        default=StatusPrzetargu.NOWY,
    )

    # AI ocena
    ai_score = models.IntegerField(null=True, blank=True)  # 0-100
    ai_uzasadnienie = models.TextField(blank=True)
    ai_czy_warto = models.BooleanField(null=True, blank=True)
    ai_uwagi = models.JSONField(default=list)  # ["Krótki termin", "Duże obciążenie"]
    ai_analizowany_at = models.DateTimeField(null=True, blank=True)

    # Powiązany kosztorys (FK do kosztorysy)
    kosztorys_id = models.IntegerField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        app_label = "przetargi"
        unique_together = [("zrodlo", "zrodlo_id", "company_id")]
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["company_id", "status"]),
            models.Index(fields=["company_id", "termin_skladania"]),
        ]

    def __str__(self):
        return f"{self.tytul[:60]} ({self.zamawiajacy})"

    @property
    def dni_do_terminu(self):
        if not self.termin_skladania:
            return None
        from django.utils import timezone
        delta = self.termin_skladania - timezone.now()
        return delta.days


class SubskrypcjaPrzetargow(models.Model):
    """Filtry automatycznego pobierania przetargów dla firmy."""

    company_id = models.IntegerField(db_index=True)
    nazwa = models.CharField(max_length=100, default="Domyślna")

    cpv_kody = models.JSONField(
        default=list,
        help_text='Kody CPV np. ["45000000-7", "45210000-2"]',
    )
    regiony = models.JSONField(
        default=list,
        help_text='Województwa np. ["małopolskie", "śląskie"]',
    )
    wartosc_min = models.DecimalField(
        max_digits=14, decimal_places=2, null=True, blank=True
    )
    wartosc_max = models.DecimalField(
        max_digits=14, decimal_places=2, null=True, blank=True
    )
    slowa_kluczowe = models.JSONField(
        default=list,
        help_text='Słowa kluczowe w tytule/opisie np. ["budynek", "remont"]',
    )
    aktywna = models.BooleanField(default=True)

    ostatnie_pobranie = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        app_label = "przetargi"

    def __str__(self):
        return f"Subskrypcja '{self.nazwa}' (firma {self.company_id})"


class EmmaWiadomoscPrzetargu(models.Model):
    """Proaktywna wiadomość Emmy o znalezionym przetargu — czeka na reakcję Romana."""

    company_id = models.IntegerField(db_index=True)
    przetarg = models.ForeignKey(
        Przetarg,
        on_delete=models.CASCADE,
        related_name="emma_wiadomosci",
    )
    tekst = models.TextField()  # rekomendacja_emma z AI
    kosztorys_id = models.IntegerField(null=True, blank=True)
    przeczytana = models.BooleanField(default=False)
    zaakceptowana = models.BooleanField(null=True, blank=True)  # None=pending
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        app_label = "przetargi"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Emma → przetarg #{self.przetarg_id} (firma {self.company_id})"


class FetchLog(models.Model):
    """Log każdego cyklu pobierania przetargów."""

    zrodlo = models.CharField(max_length=20, choices=ZrodloPrzetargu.choices)
    company_id = models.IntegerField()
    started_at = models.DateTimeField(auto_now_add=True)
    finished_at = models.DateTimeField(null=True, blank=True)
    count_fetched = models.IntegerField(default=0)
    count_new = models.IntegerField(default=0)
    blad = models.TextField(blank=True)

    class Meta:
        app_label = "przetargi"
        ordering = ["-started_at"]

    def __str__(self):
        return f"Fetch {self.zrodlo} @ {self.started_at:%Y-%m-%d %H:%M} — {self.count_new} nowych"
