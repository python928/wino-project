import random
from datetime import date

from django.db import models
from django.db.models import F
from django.utils import timezone
from rest_framework import filters, permissions, serializers, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle

from analytics.models import UserInterestProfile
from analytics.recommendations import get_recommended_products
from subscriptions.services import enforce_promotion_constraints
from users.models import Follower

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

	def get_throttles(self):
		if self.action == 'register_click':
			self.throttle_scope = 'ad_click'
			return [ScopedRateThrottle()]
		return super().get_throttles()

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

	def _haversine_km(self, lat1, lon1, lat2, lon2):
		from math import asin, cos, radians, sin, sqrt
		r = 6371.0
		dlat = radians(lat2 - lat1)
		dlon = radians(lon2 - lon1)
		a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
		return 2 * r * asin(sqrt(a))

	def _resolve_user_age(self, request):
		age_param = request.query_params.get('age')
		if age_param:
			try:
				return int(age_param)
			except (TypeError, ValueError):
				return None
		user = request.user
		if not getattr(user, 'is_authenticated', False):
			return None
		bday = getattr(user, 'birthday', None)
		if not bday:
			return None
		today = date.today()
		return today.year - bday.year - ((today.month, today.day) < (bday.month, bday.day))

	def _resolve_user_location(self, request):
		lat = request.query_params.get('lat')
		lng = request.query_params.get('lng')
		if lat and lng:
			try:
				return float(lat), float(lng)
			except (TypeError, ValueError):
				return None, None
		user = request.user
		if getattr(user, 'is_authenticated', False):
			try:
				if user.latitude is not None and user.longitude is not None:
					return float(user.latitude), float(user.longitude)
			except (TypeError, ValueError):
				pass
		return None, None

	def _resolve_user_wilaya(self, request, user_categories):
		wilaya = (
			request.query_params.get('wilaya_code')
			or request.query_params.get('wilaya')
			or request.query_params.get('state')
		)
		if wilaya:
			return str(wilaya).strip()
		# Fallback to interest profile preferred wilayas (first)
		if user_categories is not None and getattr(request.user, 'is_authenticated', False):
			try:
				profile = UserInterestProfile.objects.get(user=request.user)
				if profile.preferred_wilayas:
					return str(profile.preferred_wilayas[0])
			except UserInterestProfile.DoesNotExist:
				return None
		return None

	def _resolve_user_categories(self, request):
		if not getattr(request.user, 'is_authenticated', False):
			return []
		try:
			profile = UserInterestProfile.objects.get(user=request.user)
			return profile.get_top_categories(limit=7)
		except UserInterestProfile.DoesNotExist:
			return []

	def _resolve_recommended_products(self, request):
		if not getattr(request.user, 'is_authenticated', False):
			return []
		return get_recommended_products(request.user, limit=40)

	def _passes_audience(self, request, campaign, user_lat, user_lng, user_wilaya):
		mode = (campaign.audience_mode or '').lower()
		if mode in ('', 'all'):
			return True
		if not getattr(request.user, 'is_authenticated', False):
			return False
		if mode == 'followers':
			return Follower.objects.filter(
				user_id=request.user.id,
				followed_user_id=campaign.store_id,
			).exists()
		if mode == 'wilaya':
			return bool(user_wilaya)
		if mode == 'nearby':
			if user_lat is None or user_lng is None:
				return False
			try:
				store_lat = float(campaign.store.latitude)
				store_lng = float(campaign.store.longitude)
			except (TypeError, ValueError):
				return False
			distance = self._haversine_km(user_lat, user_lng, store_lat, store_lng)
			return distance <= 50.0
		return True

	def _passes_targeting(self, campaign, user_age, user_categories, user_lat, user_lng, user_wilaya):
		if campaign.age_from or campaign.age_to:
			if user_age is None:
				return False
			if campaign.age_from and user_age < campaign.age_from:
				return False
			if campaign.age_to and user_age > campaign.age_to:
				return False

		if campaign.target_categories:
			if not user_categories:
				return False
			if not set(user_categories).intersection(set(campaign.target_categories)):
				return False

		geo_mode = (campaign.geo_mode or '').lower()
		if geo_mode == 'wilaya':
			if not user_wilaya:
				return False
			return user_wilaya in (campaign.target_wilayas or [])
		if geo_mode == 'radius':
			if user_lat is None or user_lng is None:
				return False
			if campaign.target_radius_km is None:
				return False
			try:
				store_lat = float(campaign.store.latitude)
				store_lng = float(campaign.store.longitude)
			except (TypeError, ValueError):
				return False
			distance = self._haversine_km(user_lat, user_lng, store_lat, store_lng)
			return distance <= float(campaign.target_radius_km)
		return True

	def _score_campaign(
		self,
		campaign,
		user_categories,
		recommended_product_ids,
		recommended_category_ids,
		user_lat,
		user_lng,
	):
		score = 0.0
		if campaign.product_id and campaign.product_id in recommended_product_ids:
			score += 45.0
		if campaign.product_id and campaign.product and campaign.product.category_id:
			if campaign.product.category_id in recommended_category_ids:
				score += 25.0
			if user_categories and campaign.product.category_id in user_categories:
				score += 20.0
		if campaign.target_categories:
			matches = len(set(user_categories).intersection(set(campaign.target_categories)))
			score += min(matches * 8.0, 24.0)
		else:
			score += 6.0
		if user_lat is not None and user_lng is not None:
			try:
				store_lat = float(campaign.store.latitude)
				store_lng = float(campaign.store.longitude)
				distance = self._haversine_km(user_lat, user_lng, store_lat, store_lng)
				score += max(0.0, 20.0 - (distance * 0.4))
			except (TypeError, ValueError):
				pass
		score += random.uniform(0, 6)
		return score

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
		qs = list(self.get_queryset())
		user_categories = self._resolve_user_categories(request)
		user_age = self._resolve_user_age(request)
		user_lat, user_lng = self._resolve_user_location(request)
		user_wilaya = self._resolve_user_wilaya(request, user_categories)

		recommended = self._resolve_recommended_products(request)
		recommended_product_ids = {
			item['product'].id for item in recommended if item.get('product')
		}
		recommended_category_ids = {
			item['product'].category_id
			for item in recommended
			if item.get('product') and item['product'].category_id
		}

		scored = []
		for campaign in qs:
			if not self._passes_audience(request, campaign, user_lat, user_lng, user_wilaya):
				continue
			if not self._passes_targeting(
				campaign,
				user_age,
				user_categories,
				user_lat,
				user_lng,
				user_wilaya,
			):
				continue
			score = self._score_campaign(
				campaign,
				user_categories,
				recommended_product_ids,
				recommended_category_ids,
				user_lat,
				user_lng,
			)
			scored.append((score, campaign))

		if not scored:
			scored = [(random.uniform(0, 1), c) for c in qs]

		random.shuffle(scored)
		scored.sort(key=lambda x: x[0], reverse=True)
		ordered = [c for _, c in scored]

		page = self.paginate_queryset(ordered)
		if page is not None:
			serializer = self.get_serializer(page, many=True)
			response = self.get_paginated_response(serializer.data)
		else:
			serializer = self.get_serializer(ordered, many=True)
			response = Response(serializer.data)

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
		serializer.save(
			store=self.request.user,
			max_impressions=max_impressions,
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
		serializer.save()

	@action(detail=True, methods=['post'], url_path='register-click')
	def register_click(self, request, pk=None):
		campaign = self.get_object()
		if getattr(request.user, 'is_authenticated', False) and request.user.id == campaign.store_id:
			return Response({'status': 'ignored'})
		AdCampaign.objects.filter(id=campaign.id).update(clicks_count=F('clicks_count') + 1)
		return Response({'status': 'ok'})
