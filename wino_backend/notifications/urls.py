# Notifications app router

from django.urls import include, path
from rest_framework.routers import DefaultRouter
from fcm_django.api.rest_framework import FCMDeviceAuthorizedViewSet

from .views import NotificationViewSet

router = DefaultRouter()
router.register('notifications', NotificationViewSet, basename='notification')
router.register('devices', FCMDeviceAuthorizedViewSet, basename='device')

urlpatterns = [path('', include(router.urls))]
