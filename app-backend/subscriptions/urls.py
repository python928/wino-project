from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    MerchantSubscriptionViewSet,
    SubscriptionPaymentRequestViewSet,
    SubscriptionPlanViewSet,
)

router = DefaultRouter()
router.register('plans', SubscriptionPlanViewSet, basename='subscription-plan')
router.register('merchant-subscriptions', MerchantSubscriptionViewSet, basename='merchant-subscription')
router.register('payment-requests', SubscriptionPaymentRequestViewSet, basename='subscription-payment-request')

urlpatterns = [path('', include(router.urls))]
