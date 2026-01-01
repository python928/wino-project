from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import DeviceViewSet, NotificationViewSet

router = DefaultRouter()
router.register('notifications', NotificationViewSet, basename='notification')
router.register('devices', DeviceViewSet, basename='device')

urlpatterns = [path('', include(router.urls))]
