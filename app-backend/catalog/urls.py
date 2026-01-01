from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    CategoryViewSet,
    PackImageViewSet,
    PackProductViewSet,
    PackViewSet,
    ProductImageViewSet,
    ProductViewSet,
    ReviewViewSet,
    FavoriteViewSet,
)

router = DefaultRouter()
router.register('categories', CategoryViewSet, basename='category')
router.register('products', ProductViewSet, basename='product')
router.register('product-images', ProductImageViewSet, basename='product-image')
router.register('packs', PackViewSet, basename='pack')
router.register('pack-products', PackProductViewSet, basename='pack-product')
router.register('pack-images', PackImageViewSet, basename='pack-image')
router.register('reviews', ReviewViewSet, basename='review')
router.register('favorites', FavoriteViewSet, basename='favorite')

urlpatterns = [path('', include(router.urls))]
