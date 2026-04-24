from rest_framework.routers import DefaultRouter

from .views import AdCampaignViewSet

router = DefaultRouter()
router.register('campaigns', AdCampaignViewSet, basename='ad-campaign')

urlpatterns = router.urls
