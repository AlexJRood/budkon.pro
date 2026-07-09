from rest_framework.routers import DefaultRouter
from .views import MaterialViewSet, PozycjaZamowieniaViewSet

router = DefaultRouter()
router.register('materialy', MaterialViewSet, basename='material')
router.register('zamowienia-pozycje', PozycjaZamowieniaViewSet, basename='pozycja-zamowienia')

urlpatterns = router.urls
