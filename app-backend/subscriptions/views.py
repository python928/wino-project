from rest_framework import permissions, serializers, viewsets
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.core.validators import FileExtensionValidator

from .constants import DEFAULT_SUBSCRIPTION_INSTRUCTIONS, DEFAULT_SUBSCRIPTION_RIB
from .models import (
	MerchantSubscription,
	SubscriptionPaymentConfig,
	SubscriptionPaymentRequest,
	SubscriptionPlan,
	SubscriptionPaymentProof,
)
from .serializers import (
	MerchantSubscriptionSerializer,
	SubscriptionPaymentConfigSerializer,
	SubscriptionPaymentRequestSerializer,
	SubscriptionPlanSerializer,
)
from .services import (
	FREE_POST_LIMIT,
	approve_payment_request,
	build_merchant_dashboard,
	get_active_subscription,
	get_coin_wallet_snapshot,
	get_current_posts_count,
	get_post_limit,
	bootstrap_default_subscription_plans,
	get_merchant_plan_features,
	parse_dashboard_date_filters,
	reject_payment_request,
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
		if self.action in ['list', 'retrieve', 'access_status', 'merchant_dashboard']:
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
				'coin_wallet': get_coin_wallet_snapshot(request.user),
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
		date_from = request.query_params.get('date_from')
		date_to = request.query_params.get('date_to')
		period = request.query_params.get('period')
		debug = str(request.query_params.get('debug') or '').strip().lower() in {'1', 'true', 'yes'}
		try:
			parsed_from, parsed_to = parse_dashboard_date_filters(date_from, date_to, period=period)
		except serializers.ValidationError as exc:
			return Response(exc.detail, status=status.HTTP_400_BAD_REQUEST)

		return Response(
			build_merchant_dashboard(
				request.user,
				request,
				date_from=date_from,
				date_to=date_to,
				period=period,
				parsed_from=parsed_from,
				parsed_to=parsed_to,
				debug=debug,
			)
		)


class SubscriptionPaymentRequestViewSet(viewsets.ModelViewSet):
	queryset = SubscriptionPaymentRequest.objects.select_related('merchant', 'plan')
	serializer_class = SubscriptionPaymentRequestSerializer
	permission_classes = [permissions.IsAuthenticated]
	parser_classes = [MultiPartParser, FormParser, JSONParser]

	MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024
	ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'webp']

	def _validate_proof_image(self, image):
		validator = FileExtensionValidator(allowed_extensions=self.ALLOWED_EXTENSIONS)
		validator(image)
		if getattr(image, 'size', 0) > self.MAX_IMAGE_SIZE_BYTES:
			raise serializers.ValidationError(
				f'Image "{getattr(image, "name", "file")}" exceeds 5MB limit.'
			)

	def get_permissions(self):
		if self.action in ['list', 'retrieve', 'create']:
			return [permissions.IsAuthenticated()]
		return [permissions.IsAdminUser()]

	def get_throttles(self):
		if self.action == 'create':
			self.throttle_scope = 'payment_request_create'
			return [ScopedRateThrottle()]
		return super().get_throttles()

	def get_queryset(self):
		user = self.request.user
		if user.is_superuser or user.is_staff:
			return self.queryset
		return self.queryset.filter(merchant=user)

	def perform_create(self, serializer):
		serializer.save(merchant=self.request.user)

	def create(self, request, *args, **kwargs):
		plan_id = request.data.get('plan')
		payment_note = request.data.get('payment_note', '')
		images = request.FILES.getlist('images')
		if not plan_id:
			return Response({'plan': 'This field is required.'}, status=status.HTTP_400_BAD_REQUEST)
		if not images:
			return Response(
				{'images': 'Please upload at least 1 image as payment proof.'},
				status=status.HTTP_400_BAD_REQUEST,
			)
		if len(images) > 3:
			return Response(
				{'images': 'You can upload up to 3 images.'},
				status=status.HTTP_400_BAD_REQUEST,
			)

		try:
			for image in images:
				self._validate_proof_image(image)
		except Exception as exc:
			return Response({'images': str(exc)}, status=status.HTTP_400_BAD_REQUEST)

		serializer = self.get_serializer(data={'plan': plan_id, 'payment_note': payment_note})
		serializer.is_valid(raise_exception=True)
		payment_request = serializer.save(merchant=request.user)

		for idx, image in enumerate(images):
			SubscriptionPaymentProof.objects.create(
				payment_request=payment_request,
				image=image,
			)

		headers = self.get_success_headers(serializer.data)
		out = self.get_serializer(payment_request).data
		return Response(out, status=status.HTTP_201_CREATED, headers=headers)

	@action(detail=True, methods=['get'], url_path='timeline')
	def timeline(self, request, pk=None):
		payment_request = self.get_object()
		serializer = self.get_serializer(payment_request)
		return Response(
			{
				'id': payment_request.id,
				'status': payment_request.status,
				'timeline': serializer.data.get('timeline', []),
			}
		)

	@action(detail=True, methods=['post'], url_path='approve', permission_classes=[permissions.IsAdminUser])
	def approve(self, request, pk=None):
		payment_request = self.get_object()
		reason_code = str(request.data.get('reason_code') or '').strip()
		reason_text = str(request.data.get('reason_text') or '').strip()
		updated, changed, subscription = approve_payment_request(
			payment_request,
			reviewer=request.user,
			reason_code=reason_code,
			reason_text=reason_text,
		)
		data = self.get_serializer(updated).data
		return Response(
			{
				'request': data,
				'approved': changed,
				'activated_subscription_id': getattr(subscription, 'id', None),
			}
		)

	@action(detail=True, methods=['post'], url_path='reject', permission_classes=[permissions.IsAdminUser])
	def reject(self, request, pk=None):
		payment_request = self.get_object()
		reason_code = str(request.data.get('reason_code') or SubscriptionPaymentRequest.REASON_OTHER).strip()
		reason_text = str(request.data.get('reason_text') or '').strip()
		updated, changed = reject_payment_request(
			payment_request,
			reviewer=request.user,
			reason_code=reason_code,
			reason_text=reason_text,
		)
		data = self.get_serializer(updated).data
		return Response({'request': data, 'rejected': changed})

# Create your views here.
