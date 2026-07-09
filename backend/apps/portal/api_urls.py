from rest_framework.routers import DefaultRouter
from .views import PortalViewSet

router = DefaultRouter()
router.register('portale', PortalViewSet, basename='portal')

urlpatterns = router.urls
