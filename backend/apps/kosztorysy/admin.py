from django.contrib import admin
from .models import KnrKatalog, KnrPozycja, Kosztorys, KosztorysdzDzial, KosztorysPozycja


class KnrPozycjaInline(admin.TabularInline):
    model = KnrPozycja
    extra = 0
    fields = ["numer", "opis", "jednostka", "naklad_r", "naklad_m", "naklad_s"]


@admin.register(KnrKatalog)
class KnrKatalogAdmin(admin.ModelAdmin):
    list_display = ["kod", "nazwa"]
    search_fields = ["kod", "nazwa"]
    inlines = [KnrPozycjaInline]


@admin.register(KnrPozycja)
class KnrPozycjaAdmin(admin.ModelAdmin):
    list_display = ["katalog", "numer", "opis", "jednostka"]
    list_filter = ["katalog"]
    search_fields = ["opis", "numer"]


class KosztorysPozycjaInline(admin.TabularInline):
    model = KosztorysPozycja
    extra = 0
    fields = ["opis", "jednostka", "ilosc", "cena_jednostkowa", "kolejnosc"]


class KosztorysdzDzialInline(admin.StackedInline):
    model = KosztorysdzDzial
    extra = 0
    show_change_link = True


@admin.register(Kosztorys)
class KosztorysAdmin(admin.ModelAdmin):
    list_display = ["nazwa", "company_id", "budowa_id", "status", "created_at"]
    list_filter = ["status", "company_id"]
    search_fields = ["nazwa"]
    inlines = [KosztorysdzDzialInline]


@admin.register(KosztorysdzDzial)
class KosztorysdzDzialAdmin(admin.ModelAdmin):
    list_display = ["nazwa", "kosztorys", "kolejnosc"]
    inlines = [KosztorysPozycjaInline]
