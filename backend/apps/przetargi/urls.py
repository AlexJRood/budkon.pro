from rest_framework.routers import DefaultRouter

from .views import EmmaWiadomosciViewSet, FetchLogViewSet, PrzetargViewSet, SubskrypcjaViewSet

router = DefaultRouter()
router.register("przetargi", PrzetargViewSet, basename="przetarg")
router.register("przetargi-subskrypcje", SubskrypcjaViewSet, basename="przetarg-sub")
router.register("przetargi-logi", FetchLogViewSet, basename="przetarg-log")
router.register("emma-inbox", EmmaWiadomosciViewSet, basename="emma-inbox")

urlpatterns = router.urls
