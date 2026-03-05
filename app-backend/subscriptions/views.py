from rest_framework import permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .constants import DEFAULT_SUBSCRIPTION_INSTRUCTIONS, DEFAULT_SUBSCRIPTION_RIB
from .models import (
	MerchantSubscription,
	SubscriptionPaymentConfig,
	SubscriptionPaymentRequest,
	SubscriptionPlan,
)
from .serializers import (
	MerchantSubscriptionSerializer,
	SubscriptionPaymentConfigSerializer,
	SubscriptionPaymentRequestSerializer,
	SubscriptionPlanSerializer,
)
from .services import FREE_POST_LIMIT, get_active_subscription, get_current_posts_count, get_post_limit


class SubscriptionPlanViewSet(viewsets.ModelViewSet):
	queryset = SubscriptionPlan.objects.all()
	serializer_class = SubscriptionPlanSerializer

	def get_queryset(self):
		qs = SubscriptionPlan.objects.all()
		if self.action in ['list', 'retrieve']:
			return qs.filter(is_active=True)
		return qs

	def get_permissions(self):
		if self.action in ['list', 'retrieve', 'public_data']:
			return [permissions.AllowAny()]
		return [permissions.IsAdminUser()]

	@action(detail=False, methods=['get'], url_path='public-data')
	def public_data(self, request):
		plans = self.get_queryset()
		config = (
			SubscriptionPaymentConfig.objects.filter(is_active=True)
			.order_by('-updated_at')
			.first()
		)
		if config is None:
			config = SubscriptionPaymentConfig(
				rib=DEFAULT_SUBSCRIPTION_RIB,
				instructions=DEFAULT_SUBSCRIPTION_INSTRUCTIONS,
				is_active=True,
			)
		return Response(
			{
				'plans': SubscriptionPlanSerializer(plans, many=True).data,
				'payment_config': SubscriptionPaymentConfigSerializer(config).data,
			}
		)


class MerchantSubscriptionViewSet(viewsets.ModelViewSet):
	queryset = MerchantSubscription.objects.select_related('store', 'plan')
	serializer_class = MerchantSubscriptionSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_permissions(self):
		if self.action in ['list', 'retrieve', 'access_status']:
			return [permissions.IsAuthenticated()]
		return [permissions.IsAdminUser()]

	def get_queryset(self):
		user = self.request.user
		if user.is_superuser:
			return self.queryset
		return self.queryset.filter(store=user)

	def perform_create(self, serializer):
		# Prevent spoofing store via payload (Store == User).
		serializer.save(store=self.request.user)

	@action(detail=False, methods=['get'], url_path='access-status')
	def access_status(self, request):
		active = get_active_subscription(request.user)
		limit = get_post_limit(request.user)
		used = get_current_posts_count(request.user)
		return Response(
			{
				'has_active_subscription': active is not None,
				'free_limit': FREE_POST_LIMIT,
				'post_limit': limit,
				'used_posts': used,
				'remaining_posts': max(limit - used, 0),
				'active_subscription': MerchantSubscriptionSerializer(active).data
				if active is not None
				else None,
			}
		)


class SubscriptionPaymentRequestViewSet(viewsets.ModelViewSet):
	queryset = SubscriptionPaymentRequest.objects.select_related('merchant', 'plan')
	serializer_class = SubscriptionPaymentRequestSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_permissions(self):
		if self.action in ['list', 'retrieve', 'create']:
			return [permissions.IsAuthenticated()]
		return [permissions.IsAdminUser()]

	def get_queryset(self):
		user = self.request.user
		if user.is_superuser or user.is_staff:
			return self.queryset
		return self.queryset.filter(merchant=user)

	def perform_create(self, serializer):
		serializer.save(merchant=self.request.user)

# Create your views here.
