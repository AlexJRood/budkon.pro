from rest_framework.routers import DefaultRouter

from .views import FetchLogViewSet, PrzetargViewSet, SubskrypcjaViewSet

router = DefaultRouter()
router.register("przetargi", PrzetargViewSet, basename="przetarg")
router.register("przetargi-subskrypcje", SubskrypcjaViewSet, basename="przetarg-sub")
router.register("przetargi-logi", FetchLogViewSet, basename="przetarg-log")

urlpatterns = router.urls
