import secrets
from django.db import models
from django.utils import timezone


class PortalKlienta(models.Model):
    """
    Token dostępu do portalu klienta dla konkretnej budowy.
    Mama generuje link → wysyła klientowi → klient widzi postęp bez logowania.
    """
    company_id = models.IntegerField(db_index=True)
    budowa = models.ForeignKey(
        'budowa.Budowa', on_delete=models.CASCADE, related_name='portale'
    )
    token = models.CharField(max_length=64, unique=True, db_index=True)
    nazwa_klienta = models.CharField(max_length=255)
    email_klienta = models.EmailField(blank=True)
    telefon_klienta = models.CharField(max_length=30, blank=True)

    # Co klient może widzieć
    pokazuj_kosztorys = models.BooleanField(default=False)
    pokazuj_faktury = models.BooleanField(default=True)
    pokazuj_zdjecia = models.BooleanField(default=True)
    pokazuj_harmonogram = models.BooleanField(default=True)

    aktywny = models.BooleanField(default=True)
    wygasa = models.DateField(null=True, blank=True)  # None = nigdy

    created_at = models.DateTimeField(auto_now_add=True)
    ostatni_odczyt = models.DateTimeField(null=True, blank=True)
    liczba_odczytow = models.IntegerField(default=0)

    class Meta:
        app_label = 'portal'
        verbose_name = 'Portal klienta'
        verbose_name_plural = 'Portale klientów'

    def __str__(self):
        return f'Portal {self.nazwa_klienta} — {self.budowa}'

    def save(self, *args, **kwargs):
        if not self.token:
            self.token = secrets.token_urlsafe(48)
        super().save(*args, **kwargs)

    @property
    def jest_wazny(self) -> bool:
        if not self.aktywny:
            return False
        if self.wygasa and self.wygasa < timezone.now().date():
            return False
        return True

    def zarejestruj_odczyt(self):
        self.ostatni_odczyt = timezone.now()
        self.liczba_odczytow += 1
        self.save(update_fields=['ostatni_odczyt', 'liczba_odczytow'])

    def get_absolute_url(self) -> str:
        return f'/portal/{self.token}/'
