from rest_framework.routers import DefaultRouter
from .views import PracownikViewSet, PracownikNaBudowieViewSet

router = DefaultRouter()
router.register('pracownicy', PracownikViewSet, basename='pracownik')
router.register('pracownicy-na-budowie', PracownikNaBudowieViewSet,
                basename='pracownik-na-budowie')

urlpatterns = router.urls
