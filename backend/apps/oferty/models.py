from django.db import models
from django.utils import timezone


class StatusOferty(models.TextChoices):
    ROBOCZY = 'roboczy', 'Roboczy'
    WYSLANA = 'wyslana', 'Wysłana'
    ZAAKCEPTOWANA = 'zaakceptowana', 'Zaakceptowana'
    ODRZUCONA = 'odrzucona', 'Odrzucona'
    WYGASLA = 'wygasla', 'Wygasła'


class Oferta(models.Model):
    company_id = models.IntegerField(db_index=True)
    budowa_id = models.IntegerField(null=True, blank=True, db_index=True)
    kosztorys_id = models.IntegerField(null=True, blank=True)

    numer = models.CharField(max_length=50, blank=True)  # auto: OF/2025/001
    tytul = models.CharField(max_length=255)

    # Dane klienta (denorm — nie wymaga CRM)
    klient_nazwa = models.CharField(max_length=255)
    klient_adres = models.TextField(blank=True)
    klient_nip = models.CharField(max_length=30, blank=True)
    klient_email = models.EmailField(blank=True)
    klient_telefon = models.CharField(max_length=30, blank=True)

    # Dane wystawcy (firma Romana)
    wystawca_nazwa = models.CharField(max_length=255, blank=True)
    wystawca_adres = models.TextField(blank=True)
    wystawca_nip = models.CharField(max_length=30, blank=True)
    wystawca_email = models.EmailField(blank=True)
    wystawca_telefon = models.CharField(max_length=30, blank=True)

    # Treść
    wstep = models.TextField(blank=True)
    warunki = models.TextField(blank=True)
    uwagi = models.TextField(blank=True)

    # Snapshot pozycji z kosztorysu
    pozycje = models.JSONField(default=list)
    # [{dzial, pozycje: [{opis, jednostka, ilosc, cena_j, wartosc}]}]

    # Kwoty
    wartosc_netto = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    vat_procent = models.PositiveSmallIntegerField(default=23)
    wartosc_vat = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    wartosc_brutto = models.DecimalField(max_digits=14, decimal_places=2, default=0)

    # Rabat globalny
    rabat_procent = models.DecimalField(max_digits=5, decimal_places=2, default=0)

    # Ważność
    data_wystawienia = models.DateField(default=timezone.now)
    wazna_do = models.DateField(null=True, blank=True)

    status = models.CharField(
        max_length=20,
        choices=StatusOferty.choices,
        default=StatusOferty.ROBOCZY,
    )

    pdf_url = models.CharField(max_length=500, blank=True)  # ścieżka do wygenerowanego PDF

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.IntegerField()

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.numer or self.tytul} — {self.klient_nazwa}'

    def save(self, *args, **kwargs):
        if not self.numer:
            self.numer = self._generuj_numer()
        # Przelicz VAT
        netto = float(self.wartosc_netto)
        vat = netto * float(self.vat_procent) / 100
        self.wartosc_vat = round(vat, 2)
        self.wartosc_brutto = round(netto + vat, 2)
        super().save(*args, **kwargs)

    def _generuj_numer(self):
        rok = timezone.now().year
        ostatni = Oferta.objects.filter(
            company_id=self.company_id,
            numer__startswith=f'OF/{rok}/'
        ).count()
        return f'OF/{rok}/{str(ostatni + 1).zfill(3)}'

    @classmethod
    def z_kosztorysu(cls, kosztorys, **kwargs):
        """
        Tworzy snapshot pozycji z kosztorysu.
        kosztorys — instancja Kosztorys z prefetch dzialy__pozycje
        """
        pozycje_snapshot = []
        wartosc_netto = 0

        for dzial in kosztorys.dzialy.prefetch_related('pozycje').all():
            poz_list = []
            for p in dzial.pozycje.all():
                w = float(p.wartosc)
                wartosc_netto += w
                poz_list.append({
                    'opis': p.opis,
                    'jednostka': p.jednostka,
                    'ilosc': float(p.ilosc),
                    'cena_jednostkowa': float(p.cena_jednostkowa),
                    'wartosc': w,
                })
            pozycje_snapshot.append({
                'dzial': dzial.nazwa,
                'pozycje': poz_list,
            })

        return cls(
            pozycje=pozycje_snapshot,
            wartosc_netto=round(wartosc_netto, 2),
            **kwargs,
        )


class HistoriaStatusuOferty(models.Model):
    oferta = models.ForeignKey(
        Oferta, on_delete=models.CASCADE, related_name='historia_statusu'
    )
    status = models.CharField(max_length=20, choices=StatusOferty.choices)
    data = models.DateTimeField(auto_now_add=True)
    uwagi = models.CharField(max_length=500, blank=True)

    class Meta:
        ordering = ['data']
