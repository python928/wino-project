from django.db import models
from django.db.models import F
from django.utils import timezone
from rest_framework import filters, permissions, serializers, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from subscriptions.services import enforce_promotion_constraints

from .models import AdCampaign, AdCampaignViewer
from .serializers import AdCampaignSerializer


class IsAdOwnerOrReadOnly(permissions.BasePermission):
	def has_object_permission(self, request, _view, obj):
		if request.method in permissions.SAFE_METHODS:
			return True
		return request.user.is_superuser or obj.store_id == request.user.id


class AdCampaignViewSet(viewsets.ModelViewSet):
	queryset = AdCampaign.objects.select_related('store', 'product', 'pack')
	serializer_class = AdCampaignSerializer
	filter_backends = [filters.OrderingFilter]
	ordering_fields = ['created_at', 'percentage']

	def get_permissions(self):
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsAdOwnerOrReadOnly()]
		return [permissions.IsAuthenticated()]

	def get_queryset(self):
		qs = super().get_queryset()
		now = timezone.now()
		if self.action in ['list', 'retrieve']:
			qs = qs.filter(
				is_active=True,
			).filter(
				models.Q(start_date__isnull=True) | models.Q(start_date__lte=now)
			).filter(
				models.Q(end_date__isnull=True) | models.Q(end_date__gte=now)
			).filter(
				models.Q(max_impressions__isnull=True)
				| models.Q(impressions_count__lt=F('max_impressions'))
			)
		placement = str(self.request.query_params.get('placement') or '').strip().lower()
		if placement:
			qs = qs.filter(placement=placement)
		store_id = self.request.query_params.get('store')
		if store_id:
			qs = qs.filter(store_id=store_id)
		product_id = self.request.query_params.get('product')
		if product_id:
			qs = qs.filter(product_id=product_id)
		pack_id = self.request.query_params.get('pack')
		if pack_id:
			qs = qs.filter(pack_id=pack_id)
		return qs

	def _resolve_viewer_key(self, request):
		if getattr(request.user, 'is_authenticated', False):
			return f"user:{request.user.id}"
		session_id = str(
			request.query_params.get('session_id')
			or request.headers.get('X-Session-Id')
			or request.COOKIES.get('sessionid')
			or ''
		).strip()
		if session_id:
			return f"session:{session_id}"
		ip = str(request.META.get('REMOTE_ADDR') or 'unknown').strip()
		return f"ip:{ip}"

	def _register_impressions(self, request, campaign_ids):
		if not campaign_ids:
			return
		viewer_key = self._resolve_viewer_key(request)
		campaigns = AdCampaign.objects.filter(id__in=campaign_ids).only('id', 'store_id')
		countable_ids = []
		for campaign in campaigns:
			if getattr(request.user, 'is_authenticated', False) and request.user.id == campaign.store_id:
				continue
			countable_ids.append(campaign.id)
			hit, created = AdCampaignViewer.objects.get_or_create(
				campaign_id=campaign.id,
				viewer_key=viewer_key,
			)
			if not created:
				hit.save(update_fields=['last_seen_at'])
				continue
			AdCampaign.objects.filter(id=campaign.id).update(
				unique_viewers_count=F('unique_viewers_count') + 1,
			)
		if not countable_ids:
			return
		AdCampaign.objects.filter(id__in=countable_ids).update(
			impressions_count=F('impressions_count') + 1
		)
		AdCampaign.objects.filter(
			id__in=countable_ids,
			max_impressions__isnull=False,
			impressions_count__gte=F('max_impressions'),
		).update(is_active=False)

	def list(self, request, *args, **kwargs):
		response = super().list(request, *args, **kwargs)
		payload = response.data
		ids = []
		if isinstance(payload, dict):
			items = payload.get('results') if isinstance(payload.get('results'), list) else []
			ids = [item.get('id') for item in items if isinstance(item, dict) and item.get('id')]
		elif isinstance(payload, list):
			ids = [item.get('id') for item in payload if isinstance(item, dict) and item.get('id')]
		self._register_impressions(request, ids)
		return response

	def retrieve(self, request, *args, **kwargs):
		response = super().retrieve(request, *args, **kwargs)
		campaign_id = response.data.get('id') if isinstance(response.data, dict) else None
		if campaign_id:
			self._register_impressions(request, [campaign_id])
		return response

	def perform_create(self, serializer):
		target_product = serializer.validated_data.get('product')
		target_pack = serializer.validated_data.get('pack')
		if target_product is not None and target_product.store_id != self.request.user.id:
			raise serializers.ValidationError({'product': 'Target product must belong to the merchant.'})
		if target_pack is not None and target_pack.merchant_id != self.request.user.id:
			raise serializers.ValidationError({'pack': 'Target pack must belong to the merchant.'})

		start_date = serializer.validated_data.get('start_date')
		end_date = serializer.validated_data.get('end_date')
		features = enforce_promotion_constraints(
			self.request.user,
			start_date=start_date,
			end_date=end_date,
			kind='advertising',
		)
		max_impressions = serializer.validated_data.get('max_impressions')
		if max_impressions in (None, ''):
			max_impressions = features.get('ad_max_impressions')
		priority_boost = serializer.validated_data.get('priority_boost')
		if priority_boost in (None, ''):
			priority_boost = features.get('ad_priority_boost')
		else:
			plan_boost = features.get('ad_priority_boost')
			if plan_boost is not None and int(priority_boost) > int(plan_boost):
				raise serializers.ValidationError(
					{'priority_boost': f'Priority boost exceeds plan limit ({plan_boost}).'}
				)
		serializer.save(
			store=self.request.user,
			max_impressions=max_impressions,
			priority_boost=priority_boost or 0,
		)

	def perform_update(self, serializer):
		target_product = serializer.validated_data.get('product', serializer.instance.product)
		target_pack = serializer.validated_data.get('pack', serializer.instance.pack)
		if target_product is not None and target_product.store_id != self.request.user.id:
			raise serializers.ValidationError({'product': 'Target product must belong to the merchant.'})
		if target_pack is not None and target_pack.merchant_id != self.request.user.id:
			raise serializers.ValidationError({'pack': 'Target pack must belong to the merchant.'})

		start_date = serializer.validated_data.get('start_date', serializer.instance.start_date)
		end_date = serializer.validated_data.get('end_date', serializer.instance.end_date)
		features = enforce_promotion_constraints(
			self.request.user,
			start_date=start_date,
			end_date=end_date,
			promotion_id=serializer.instance.id,
			kind='advertising',
		)
		max_impressions = serializer.validated_data.get('max_impressions', serializer.instance.max_impressions)
		plan_limit = features.get('ad_max_impressions')
		if plan_limit and max_impressions and int(max_impressions) > int(plan_limit):
			raise serializers.ValidationError(
				{'max_impressions': f'Max impressions exceeds your plan limit ({plan_limit}).'}
			)
		priority_boost = serializer.validated_data.get('priority_boost', serializer.instance.priority_boost)
		plan_boost = features.get('ad_priority_boost')
		if plan_boost is not None and priority_boost and int(priority_boost) > int(plan_boost):
			raise serializers.ValidationError(
				{'priority_boost': f'Priority boost exceeds plan limit ({plan_boost}).'}
			)
		serializer.save()

	@action(detail=True, methods=['post'], url_path='register-click')
	def register_click(self, request, pk=None):
		campaign = self.get_object()
		if getattr(request.user, 'is_authenticated', False) and request.user.id == campaign.store_id:
			return Response({'status': 'ignored'})
		AdCampaign.objects.filter(id=campaign.id).update(clicks_count=F('clicks_count') + 1)
		return Response({'status': 'ok'})
