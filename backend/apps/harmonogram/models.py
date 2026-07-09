from django.db import models

from apps.budowa.models import Budowa, EtapBudowy


class ZadanieHarmonogramu(models.Model):
    """
    Zadanie / aktywność w harmonogramie budowy.
    Należy do etapu; może mieć zależności (poprzedniki).
    """

    company_id = models.IntegerField(db_index=True)
    budowa = models.ForeignKey(
        Budowa, on_delete=models.CASCADE, related_name="zadania"
    )
    etap = models.ForeignKey(
        EtapBudowy,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="zadania",
    )
    nazwa = models.CharField(max_length=255)
    opis = models.TextField(blank=True)
    kolejnosc = models.PositiveIntegerField(default=0)
    status = models.CharField(
        max_length=20,
        choices=[
            ("planowane", "Planowane"),
            ("w_toku", "W toku"),
            ("zakonczone", "Zakończone"),
            ("wstrzymane", "Wstrzymane"),
        ],
        default="planowane",
    )
    data_start = models.DateField(null=True, blank=True)
    data_koniec = models.DateField(null=True, blank=True)
    czas_trwania_dni = models.PositiveIntegerField(null=True, blank=True)
    postep_procent = models.PositiveSmallIntegerField(default=0)  # 0–100
    # Budżet zadania (podzbiór budżetu etapu)
    budzet = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    kosztorys_id = models.IntegerField(null=True, blank=True)
    # Poprzednicy (FS dependency)
    poprzednicy = models.ManyToManyField(
        "self",
        symmetrical=False,
        blank=True,
        related_name="nastepniki",
    )
    # Przypisani pracownicy (contact_id z CRM)
    assigned_ids = models.JSONField(default=list, blank=True)

    class Meta:
        ordering = ["kolejnosc", "data_start"]
        verbose_name_plural = "zadania harmonogramu"

    def __str__(self):
        return f"{self.budowa.nazwa} / {self.nazwa}"

    @property
    def opoznienie_dni(self) -> int | None:
        """Ile dni zadanie jest opóźnione (>0) lub ile pozostało (<0)."""
        from datetime import date

        if not self.data_koniec or self.status == "zakonczone":
            return None
        delta = (date.today() - self.data_koniec).days
        return delta if delta > 0 else None


class MilestoneHarmonogramu(models.Model):
    """
    Kamień milowy — ważna data w harmonogramie (np. odbiór, płatność).
    Nie ma czasu trwania.
    """

    company_id = models.IntegerField(db_index=True)
    budowa = models.ForeignKey(
        Budowa, on_delete=models.CASCADE, related_name="milestones"
    )
    etap = models.ForeignKey(
        EtapBudowy,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    nazwa = models.CharField(max_length=255)
    data = models.DateField()
    osiagniety = models.BooleanField(default=False)
    kolor = models.CharField(max_length=7, default="#FF9800")  # hex

    class Meta:
        ordering = ["data"]
