from django.contrib import admin

from .models import FetchLog, Przetarg, SubskrypcjaPrzetargow


@admin.register(Przetarg)
class PrzetargAdmin(admin.ModelAdmin):
    list_display = [
        "tytul",
        "zamawiajacy",
        "wartosc_szacunkowa",
        "termin_skladania",
        "status",
        "ai_score",
        "ai_czy_warto",
        "zrodlo",
        "created_at",
    ]
    list_filter = ["status", "zrodlo", "ai_czy_warto"]
    search_fields = ["tytul", "zamawiajacy", "opis"]
    readonly_fields = [
        "zrodlo_id",
        "zrodlo_url",
        "raw_data",
        "ai_analizowany_at",
        "created_at",
        "updated_at",
    ]
    fieldsets = (
        (
            "Dane przetargu",
            {
                "fields": (
                    "company_id",
                    "tytul",
                    "zamawiajacy",
                    "opis",
                    "wartosc_szacunkowa",
                    "waluta",
                    "termin_skladania",
                    "termin_realizacji",
                    "lokalizacja",
                    "cpv_kody",
                )
            },
        ),
        (
            "Źródło",
            {"fields": ("zrodlo", "zrodlo_id", "zrodlo_url"), "classes": ("collapse",)},
        ),
        (
            "Status & kosztorys",
            {"fields": ("status", "kosztorys_id")},
        ),
        (
            "AI ocena",
            {
                "fields": (
                    "ai_score",
                    "ai_czy_warto",
                    "ai_uzasadnienie",
                    "ai_uwagi",
                    "ai_analizowany_at",
                )
            },
        ),
    )


@admin.register(SubskrypcjaPrzetargow)
class SubskrypcjaAdmin(admin.ModelAdmin):
    list_display = ["nazwa", "company_id", "aktywna", "ostatnie_pobranie"]
    list_filter = ["aktywna"]


@admin.register(FetchLog)
class FetchLogAdmin(admin.ModelAdmin):
    list_display = ["zrodlo", "company_id", "started_at", "count_new", "blad"]
    list_filter = ["zrodlo"]
    readonly_fields = ["started_at", "finished_at", "count_fetched", "count_new", "blad"]
