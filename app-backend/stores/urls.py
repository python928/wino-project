from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import FollowerViewSet, StoreViewSet

router = DefaultRouter()
router.register('stores', StoreViewSet, basename='store')
router.register('followers', FollowerViewSet, basename='follower')

urlpatterns = [
    path('', include(router.urls)),
]
