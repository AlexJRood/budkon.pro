from rest_framework.routers import DefaultRouter
from .views import OfertyViewSet

router = DefaultRouter()
router.register('oferty', OfertyViewSet, basename='oferta')

urlpatterns = router.urls
