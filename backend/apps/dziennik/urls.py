from rest_framework.routers import DefaultRouter

from .views import WpisDziennikViewSet

router = DefaultRouter()
router.register("dziennik", WpisDziennikViewSet, basename="dziennik")

urlpatterns = router.urls
