from rest_framework.routers import DefaultRouter

from .views import MilestoneViewSet, TimelineViewSet, ZadanieViewSet

router = DefaultRouter()
router.register("harmonogram", ZadanieViewSet, basename="harmonogram")
router.register("harmonogram-milestones", MilestoneViewSet, basename="harmonogram-ms")
router.register("harmonogram/timeline", TimelineViewSet, basename="harmonogram-timeline")

urlpatterns = router.urls
