from django.urls import path

from .views import RecommendationsAPIView

urlpatterns = [
	path('recommendations/', RecommendationsAPIView.as_view(), name='analytics-recommendations'),
]
