from rest_framework import permissions, viewsets

from .models import MerchantSubscription, SubscriptionPlan
from .serializers import MerchantSubscriptionSerializer, SubscriptionPlanSerializer


class SubscriptionPlanViewSet(viewsets.ModelViewSet):
	queryset = SubscriptionPlan.objects.all()
	serializer_class = SubscriptionPlanSerializer

	def get_permissions(self):
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		return [permissions.IsAdminUser()]


class MerchantSubscriptionViewSet(viewsets.ModelViewSet):
	queryset = MerchantSubscription.objects.select_related('store', 'plan')
	serializer_class = MerchantSubscriptionSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_queryset(self):
		user = self.request.user
		if user.is_superuser:
			return self.queryset
		return self.queryset.filter(store__owner=user)

	def perform_create(self, serializer):
		serializer.save()

# Create your views here.
