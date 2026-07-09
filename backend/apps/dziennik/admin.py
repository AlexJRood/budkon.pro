from django.contrib import admin

from .models import ObecnoscNaBudowie, WpisDziennika, ZdjecieDziennika


class ObecnoscInline(admin.TabularInline):
    model = ObecnoscNaBudowie
    extra = 0
    fields = ["imie_nazwisko", "rola", "godziny", "contact_id"]


class ZdjecieInline(admin.TabularInline):
    model = ZdjecieDziennika
    extra = 0
    readonly_fields = ["created_at"]


@admin.register(WpisDziennika)
class WpisDziennikAdmin(admin.ModelAdmin):
    list_display = [
        "data", "budowa", "pogoda", "temperatura",
        "godziny_pracy", "liczba_pracownikow", "pogoda_auto",
    ]
    list_filter = ["pogoda", "pogoda_auto"]
    search_fields = ["budowa__nazwa", "opis"]
    inlines = [ObecnoscInline, ZdjecieInline]
    readonly_fields = ["pogoda_auto", "created_at", "updated_at"]
