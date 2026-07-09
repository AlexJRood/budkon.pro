from decimal import Decimal
from django.db import models
from django.utils import timezone


class TypFaktury(models.TextChoices):
    SPRZEDAZ = 'sprzedaz', 'Faktura sprzedaży'
    ZALICZKOWA = 'zaliczkowa', 'Faktura zaliczkowa'
    KONCOWA = 'koncowa', 'Faktura końcowa'
    KORYGUJACA = 'korygujaca', 'Faktura korygująca'
    PROFORMA = 'proforma', 'Proforma'


class StatusFaktury(models.TextChoices):
    SZKIC = 'szkic', 'Szkic'
    WYSTAWIONA = 'wystawiona', 'Wystawiona'
    WYSLANA = 'wyslana', 'Wysłana'
    OPLACONA = 'oplacona', 'Opłacona'
    PRZETERMINOWANA = 'przeterminowana', 'Przeterminowana'
    ANULOWANA = 'anulowana', 'Anulowana'


class MetodaPlatnosci(models.TextChoices):
    PRZELEW = 'przelew', 'Przelew bankowy'
    GOTOWKA = 'gotowka', 'Gotówka'
    KARTA = 'karta', 'Karta płatnicza'
    BLIK = 'blik', 'BLIK'


class Faktura(models.Model):
    company_id = models.IntegerField(db_index=True)

    # Numer faktury — np. FV/2025/001
    numer = models.CharField(max_length=30, unique=True, blank=True)
    typ = models.CharField(
        max_length=15, choices=TypFaktury.choices, default=TypFaktury.SPRZEDAZ
    )
    status = models.CharField(
        max_length=20, choices=StatusFaktury.choices, default=StatusFaktury.SZKIC
    )

    # Powiązania
    budowa = models.ForeignKey(
        'budowa.Budowa', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='faktury'
    )
    oferta = models.ForeignKey(
        'oferty.Oferta', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='faktury'
    )

    # Wystawca (domyślnie z ustawień firmy)
    wystawca_nazwa = models.CharField(max_length=255, default='')
    wystawca_nip = models.CharField(max_length=20, blank=True)
    wystawca_adres = models.TextField(blank=True)
    wystawca_konto = models.CharField(max_length=34, blank=True)  # IBAN

    # Nabywca
    nabywca_nazwa = models.CharField(max_length=255)
    nabywca_nip = models.CharField(max_length=20, blank=True)
    nabywca_adres = models.TextField(blank=True)

    # Daty
    data_wystawienia = models.DateField(default=timezone.now)
    data_sprzedazy = models.DateField(null=True, blank=True)
    termin_platnosci = models.DateField()

    metoda_platnosci = models.CharField(
        max_length=15, choices=MetodaPlatnosci.choices, default=MetodaPlatnosci.PRZELEW
    )

    # Pozycje jako JSON snapshot (tak jak w Ofercie)
    pozycje = models.JSONField(default=list)

    # Sumy (denormalizowane, przeliczane przy zapisie)
    wartosc_netto = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    wartosc_vat = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    wartosc_brutto = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    stawka_vat = models.IntegerField(default=23)  # %

    uwagi = models.TextField(blank=True)
    pdf_path = models.CharField(max_length=500, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    data_oplacenia = models.DateField(null=True, blank=True)

    class Meta:
        app_label = 'faktury'
        ordering = ['-data_wystawienia', '-id']
        verbose_name_plural = 'faktury'

    def __str__(self):
        return f"{self.numer or 'Szkic'} — {self.nabywca_nazwa}"

    def save(self, *args, **kwargs):
        if not self.numer and self.status != StatusFaktury.SZKIC:
            self.numer = self._generuj_numer()
        self._przelicz()
        super().save(*args, **kwargs)

    def _generuj_numer(self) -> str:
        rok = self.data_wystawienia.year if self.data_wystawienia else timezone.now().year
        ostatnia = Faktura.objects.filter(
            company_id=self.company_id,
            numer__startswith=f'FV/{rok}/',
        ).order_by('-numer').first()
        if ostatnia:
            try:
                seq = int(ostatnia.numer.split('/')[-1]) + 1
            except (ValueError, IndexError):
                seq = 1
        else:
            seq = 1
        return f'FV/{rok}/{seq:03d}'

    def _przelicz(self):
        netto = Decimal('0')
        for p in self.pozycje:
            ilosc = Decimal(str(p.get('ilosc', 1)))
            cena = Decimal(str(p.get('cena_netto', 0)))
            netto += ilosc * cena
        vat = netto * Decimal(str(self.stawka_vat)) / Decimal('100')
        self.wartosc_netto = netto.quantize(Decimal('0.01'))
        self.wartosc_vat = vat.quantize(Decimal('0.01'))
        self.wartosc_brutto = (netto + vat).quantize(Decimal('0.01'))

    @property
    def jest_przeterminowana(self) -> bool:
        from datetime import date
        return (
            self.status == StatusFaktury.WYSTAWIONA
            and self.termin_platnosci < date.today()
        )

    @classmethod
    def z_oferty(cls, oferta, **kwargs) -> 'Faktura':
        """Tworzy fakturę kopiując pozycje z oferty."""
        from datetime import date, timedelta
        return cls(
            company_id=oferta.company_id,
            oferta=oferta,
            nabywca_nazwa=oferta.klient_nazwa,
            nabywca_nip=oferta.klient_nip or '',
            nabywca_adres=oferta.klient_adres or '',
            pozycje=oferta.pozycje,
            stawka_vat=oferta.stawka_vat,
            data_wystawienia=date.today(),
            data_sprzedazy=date.today(),
            termin_platnosci=date.today() + timedelta(days=14),
            **kwargs,
        )
