from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import PromotionImageViewSet, PromotionViewSet

router = DefaultRouter()
router.register('promotions', PromotionViewSet, basename='promotion')
router.register('promotion-images', PromotionImageViewSet, basename='promotion-image')

urlpatterns = [path('', include(router.urls))]
