from django.urls import path
from .views import portal_klienta

urlpatterns = [
    path('portal/<str:token>/', portal_klienta, name='portal-klienta'),
]
