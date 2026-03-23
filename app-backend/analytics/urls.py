from django.urls import path

from .views import InteractionEventAPIView, RecommendationsAPIView, TrustSignalAPIView

urlpatterns = [
	path('recommendations/', RecommendationsAPIView.as_view(), name='analytics-recommendations'),
	path('events/', InteractionEventAPIView.as_view(), name='analytics-events'),
	path('trust-signals/', TrustSignalAPIView.as_view(), name='analytics-trust-signals'),
]
