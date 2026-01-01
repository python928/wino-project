from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import MerchantSubscriptionViewSet, SubscriptionPlanViewSet

router = DefaultRouter()
router.register('plans', SubscriptionPlanViewSet, basename='subscription-plan')
router.register('merchant-subscriptions', MerchantSubscriptionViewSet, basename='merchant-subscription')

urlpatterns = [path('', include(router.urls))]
