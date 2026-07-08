from django.db import models


class Budowa(models.Model):
    """Projekt budowlany — odpowiednik 'transakcji' w hously.pro."""
    company_id = models.IntegerField(db_index=True)   # multi-tenancy
    nazwa = models.CharField(max_length=255)
    adres = models.CharField(max_length=500, blank=True)
    zamawiajacy_id = models.IntegerField(null=True, blank=True)  # UserContact z CRM
    status = models.CharField(
        max_length=30,
        choices=[
            ("oferta", "Oferta"),
            ("umowa", "Umowa podpisana"),
            ("w_toku", "W toku"),
            ("zakonczona", "Zakończona"),
            ("anulowana", "Anulowana"),
        ],
        default="oferta",
    )
    data_rozpoczecia = models.DateField(null=True, blank=True)
    data_planowanego_zakonczenia = models.DateField(null=True, blank=True)
    budzet = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.IntegerField()

    class Meta:
        verbose_name_plural = "budowy"

    def __str__(self):
        return self.nazwa


class EtapBudowy(models.Model):
    """Etap/faza projektu budowlanego."""
    ETAPY = [
        ("projekt", "Projekt"),
        ("pozwolenie", "Pozwolenie na budowę"),
        ("fundamenty", "Fundamenty"),
        ("stan_surowy", "Stan surowy zamknięty"),
        ("dach", "Dach"),
        ("instalacje", "Instalacje"),
        ("wykonczenie", "Wykończenie"),
        ("odbiory", "Odbiory"),
        ("gwarancja", "Okres gwarancji"),
    ]
    budowa = models.ForeignKey(Budowa, on_delete=models.CASCADE, related_name="etapy")
    nazwa = models.CharField(max_length=100)
    typ = models.CharField(max_length=30, choices=ETAPY, blank=True)
    kolejnosc = models.PositiveIntegerField(default=0)
    status = models.CharField(
        max_length=20,
        choices=[("planowany", "Planowany"), ("w_toku", "W toku"), ("zakończony", "Zakończony")],
        default="planowany",
    )
    data_start = models.DateField(null=True, blank=True)
    data_koniec = models.DateField(null=True, blank=True)
    budzet_etapu = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    kosztorys_id = models.IntegerField(null=True, blank=True)  # FK do Kosztorys

    class Meta:
        ordering = ["kolejnosc"]

    def __str__(self):
        return f"{self.budowa.nazwa} — {self.nazwa}"
