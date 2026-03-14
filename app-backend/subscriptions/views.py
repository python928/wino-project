from rest_framework import permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Count, Q
from django.utils import timezone

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
from catalog.serializers import PromotionSerializer
from .services import (
	FREE_POST_LIMIT,
	get_active_subscription,
	get_current_posts_count,
	get_post_limit,
	bootstrap_default_subscription_plans,
	get_merchant_plan_features,
)


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
		bootstrap_default_subscription_plans()
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
		plan_features = get_merchant_plan_features(request.user)
		return Response(
			{
				'has_active_subscription': active is not None,
				'free_limit': FREE_POST_LIMIT,
				'post_limit': limit,
				'used_posts': used,
				'remaining_posts': max(limit - used, 0),
				'plan_features': plan_features,
				'active_subscription': MerchantSubscriptionSerializer(active).data
				if active is not None
				else None,
			}
		)

	@action(detail=False, methods=['get'], url_path='merchant-dashboard')
	def merchant_dashboard(self, request):
		"""
		Dashboard data for merchants: subscription status + ad/promotion analytics.
		"""
		from catalog.models import Product, Promotion
		from analytics.models import InteractionLog

		active = get_active_subscription(request.user)
		plan_features = get_merchant_plan_features(request.user)

		days_remaining = None
		if active is not None:
			days_remaining = max(0, (active.end_date - timezone.now()).days)

		promotions_qs = Promotion.objects.filter(store=request.user).order_by('-created_at')
		promotions_data = PromotionSerializer(promotions_qs, many=True).data

		product_stats = (
			InteractionLog.objects.filter(product__store=request.user)
			.values('product_id', 'product__name')
			.annotate(
				views=Count('id', filter=Q(action='view')),
				clicks=Count('id', filter=Q(action='click')),
				favorites=Count('id', filter=Q(action='favorite')),
				promotion_clicks=Count('id', filter=Q(action='promotion_click')),
			)
			.order_by('-views', '-clicks')
		)

		return Response(
			{
				'active_subscription': MerchantSubscriptionSerializer(active).data
				if active is not None
				else None,
				'days_remaining': days_remaining,
				'plan_features': plan_features,
				'promotions': promotions_data,
				'product_stats': list(product_stats),
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
