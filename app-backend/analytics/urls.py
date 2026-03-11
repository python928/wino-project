from django.urls import path

from .views import InteractionEventAPIView, RecommendationsAPIView

urlpatterns = [
	path('recommendations/', RecommendationsAPIView.as_view(), name='analytics-recommendations'),
	path('events/', InteractionEventAPIView.as_view(), name='analytics-events'),
]
