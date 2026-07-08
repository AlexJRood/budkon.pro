from rest_framework.routers import DefaultRouter
from .views import BudowaViewSet, EtapBudowyViewSet

router = DefaultRouter()
router.register("budowy", BudowaViewSet, basename="budowa")
router.register("etapy", EtapBudowyViewSet, basename="etap")

urlpatterns = router.urls
