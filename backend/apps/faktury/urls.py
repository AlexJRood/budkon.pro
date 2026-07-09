from rest_framework.routers import DefaultRouter
from .views import FakturaViewSet

router = DefaultRouter()
router.register('faktury', FakturaViewSet, basename='faktura')

urlpatterns = router.urls
