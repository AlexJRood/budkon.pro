from rest_framework.routers import DefaultRouter
from .views import KontrahentViewSet, PowiazaniePodwykonawcyViewSet

router = DefaultRouter()
router.register("kontakty", KontrahentViewSet, basename="kontrahent")
router.register("podwykonawcy", PowiazaniePodwykonawcyViewSet, basename="podwykonawca")

urlpatterns = router.urls
