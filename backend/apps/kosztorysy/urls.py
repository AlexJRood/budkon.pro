from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    KnrKatalogViewSet,
    KnrPozycjaViewSet,
    KosztorysViewSet,
    KosztorysdzDzialViewSet,
    KosztorysPozycjaViewSet,
)

router = DefaultRouter()
router.register("knr/katalogi", KnrKatalogViewSet, basename="knr-katalog")
router.register("knr/pozycje", KnrPozycjaViewSet, basename="knr-pozycja")
router.register("kosztorysy", KosztorysViewSet, basename="kosztorys")
router.register("kosztorysy-dzialy", KosztorysdzDzialViewSet, basename="kosztorys-dzial")
router.register("kosztorysy-pozycje", KosztorysPozycjaViewSet, basename="kosztorys-pozycja")

urlpatterns = [path("", include(router.urls))]
