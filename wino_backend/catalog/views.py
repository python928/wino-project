from django.db import models
from django.utils import timezone
from datetime import timedelta
from rest_framework import filters, permissions, viewsets, status, serializers
from rest_framework.throttling import ScopedRateThrottle
import math
from .search_engine import calculate_adaptive_radius, apply_weighted_ranking
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from django.core.validators import FileExtensionValidator

from .models import Category, Pack, PackImage, PackProduct, Product, ProductImage, Review, Favorite, Promotion, PromotionImage, ProductReport, PromotionViewer
from .serializers import (
	CategorySerializer,
	PackImageSerializer,
	PackProductSerializer,
	PackSerializer,
	ProductImageSerializer,
	ProductSerializer,
	ReviewSerializer,
	FavoriteSerializer,
	PromotionSerializer,
	PromotionImageSerializer,
	ProductReportSerializer,
)
from users.models import User, TrustSettings
from users.abuse import record_abuse_signal
from users.trust_scoring import score_product_report, score_review_credibility, evaluate_store_verification
from subscriptions.services import ensure_can_create_post, enforce_promotion_constraints
from analytics.models import InteractionLog

# NOTE: Store == users.User now (unified profile)

MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024
ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'webp']


def _as_bool(value):
	return str(value or '').strip().lower() in {'1', 'true', 'yes', 'on'}


def _as_positive_int(value, default_value):
	try:
		parsed = int(value)
		return parsed if parsed > 0 else default_value
	except (TypeError, ValueError):
		return default_value


def _as_float(value, default_value=0.0):
	try:
		return float(value)
	except (TypeError, ValueError):
		return default_value


def _target_feed_size(request, default_size=12):
	raw_size = request.query_params.get('page_size') or request.query_params.get('limit')
	target_size = _as_positive_int(raw_size, default_size)
	return max(6, min(target_size, 40))


def _has_at_least_n_items(queryset, target_count):
	if target_count <= 1:
		return queryset.exists()
	sample_ids = list(
		queryset.values_list('id', flat=True).distinct()[:target_count]
	)
	return len(sample_ids) >= target_count


def _apply_city_scope_with_baladiya_fallback(
	queryset,
	request,
	wilaya_code,
	baladiya,
	wilaya_scope_q,
	baladiya_scope_q,
	baladiya_only_q,
):
	target_size = _target_feed_size(request)
	if wilaya_code:
		if baladiya:
			strict_qs = queryset.filter(baladiya_scope_q)
			if _has_at_least_n_items(strict_qs, target_size):
				return strict_qs

		wilaya_qs = queryset.filter(wilaya_scope_q)
		if _has_at_least_n_items(wilaya_qs, target_size):
			return wilaya_qs

		# Last fallback: keep feed populated instead of returning an empty city page
		return queryset

	if baladiya:
		baladiya_qs = queryset.filter(baladiya_only_q)
		if _has_at_least_n_items(baladiya_qs, target_size):
			return baladiya_qs
		return queryset

	return queryset


def _bayesian_rating(average_rating, vote_count, global_average=3.5, minimum_votes=5.0):
	avg = _as_float(average_rating, global_average)
	votes = max(_as_float(vote_count, 0.0), 0.0)
	min_votes = max(_as_float(minimum_votes, 1.0), 1.0)
	if votes <= 0:
		return _as_float(global_average, 3.5)
	weight = votes / (votes + min_votes)
	return (weight * avg) + ((1.0 - weight) * _as_float(global_average, 3.5))


def _recency_boost(created_at, now, horizon_hours=72):
	if created_at is None:
		return 0.0
	age_seconds = max((now - created_at).total_seconds(), 0.0)
	horizon_seconds = max(float(horizon_hours) * 3600.0, 1.0)
	if age_seconds >= horizon_seconds:
		return 0.0
	return 1.0 - (age_seconds / horizon_seconds)


def _apply_ranked_order(queryset, ranked_ids, fallback_order='-created_at'):
	if not ranked_ids:
		return queryset
	when_clauses = [
		models.When(id=pk, then=index)
		for index, pk in enumerate(ranked_ids)
	]
	order_case = models.Case(
		*when_clauses,
		default=models.Value(len(ranked_ids) + 1000),
		output_field=models.IntegerField(),
	)
	return queryset.annotate(_home_rank_order=order_case).order_by('_home_rank_order', fallback_order)


def _rank_products_for_home(queryset, request):
	if not _as_bool(request.query_params.get('home_rank')):
		return queryset

	now = timezone.now()
	window_hours = _as_positive_int(request.query_params.get('home_window_hours'), 168)
	candidate_limit = _as_positive_int(request.query_params.get('home_candidate_limit'), 300)
	recent_cutoff = now - timedelta(hours=window_hours)
	week_cutoff = now - timedelta(days=7)

	candidates = list(queryset.select_related('store', 'category')[:candidate_limit])
	if not candidates:
		return queryset

	product_ids = [product.id for product in candidates]

	review_rows = (
		Review.objects.filter(product_id__in=product_ids)
		.values('product_id')
		.annotate(
			avg_rating=models.Avg('rating'),
			total_reviews=models.Count('id'),
			recent_avg_rating=models.Avg('rating', filter=models.Q(created_at__gte=recent_cutoff)),
			recent_reviews=models.Count('id', filter=models.Q(created_at__gte=recent_cutoff)),
		)
	)
	reviews_by_product = {
		int(row['product_id']): row
		for row in review_rows
	}

	weighted_rating_sum = 0.0
	weighted_rating_votes = 0
	for row in review_rows:
		votes = int(row.get('total_reviews') or 0)
		avg = _as_float(row.get('avg_rating'), 0.0)
		weighted_rating_sum += (avg * votes)
		weighted_rating_votes += votes
	global_average = (weighted_rating_sum / weighted_rating_votes) if weighted_rating_votes > 0 else 3.5

	interaction_rows = (
		InteractionLog.objects.filter(
			product_id__in=product_ids,
			action__in=['view', 'click'],
			timestamp__gte=week_cutoff,
		)
		.values('product_id')
		.annotate(
			recent_hits=models.Count('id', filter=models.Q(timestamp__gte=recent_cutoff)),
			week_hits=models.Count('id'),
		)
	)
	interactions_by_product = {
		int(row['product_id']): row
		for row in interaction_rows
	}

	ranked_entries = []
	for product in candidates:
		review_stats = reviews_by_product.get(product.id, {})
		interaction_stats = interactions_by_product.get(product.id, {})

		total_reviews = int(review_stats.get('total_reviews') or 0)
		recent_reviews = int(review_stats.get('recent_reviews') or 0)
		avg_rating = _as_float(review_stats.get('avg_rating'), global_average)
		recent_avg_rating = _as_float(review_stats.get('recent_avg_rating'), avg_rating)

		recent_rating_score = _bayesian_rating(
			recent_avg_rating,
			recent_reviews,
			global_average=global_average,
			minimum_votes=3.0,
		)
		overall_rating_score = _bayesian_rating(
			avg_rating,
			total_reviews,
			global_average=global_average,
			minimum_votes=8.0,
		)
		rating_score = (
			(recent_rating_score * 0.75) + (overall_rating_score * 0.25)
			if recent_reviews > 0
			else overall_rating_score
		)

		recent_hits = int(interaction_stats.get('recent_hits') or 0)
		week_hits = int(interaction_stats.get('week_hits') or 0)
		popularity_score = math.log1p(max((recent_hits * 2) + week_hits, 0))
		review_volume_score = math.log1p(max((recent_reviews * 2) + total_reviews, 0))
		freshness_score = _recency_boost(getattr(product, 'created_at', None), now, horizon_hours=96)

		final_score = (
			(rating_score * 18.0)
			+ (review_volume_score * 2.4)
			+ (popularity_score * 4.2)
			+ (freshness_score * 5.0)
		)
		has_ratings = 1 if total_reviews > 0 else 0
		ranked_entries.append((product.id, has_ratings, final_score, product.created_at))

	ranked_entries.sort(key=lambda item: (item[1], item[2], item[3]), reverse=True)
	ranked_ids = [item[0] for item in ranked_entries]
	return _apply_ranked_order(queryset, ranked_ids)


def _rank_promotions_for_home(queryset, request):
	if not _as_bool(request.query_params.get('home_rank')):
		return queryset

	now = timezone.now()
	window_hours = _as_positive_int(request.query_params.get('home_window_hours'), 168)
	candidate_limit = _as_positive_int(request.query_params.get('home_candidate_limit'), 300)
	recent_cutoff = now - timedelta(hours=window_hours)
	week_cutoff = now - timedelta(days=7)

	candidates = list(queryset.select_related('product')[:candidate_limit])
	if not candidates:
		return queryset

	promotion_ids = [promo.id for promo in candidates]
	product_ids = [promo.product_id for promo in candidates if promo.product_id]

	reviews_by_product = {}
	global_average = 3.5
	if product_ids:
		review_rows = (
			Review.objects.filter(product_id__in=product_ids)
			.values('product_id')
			.annotate(
				avg_rating=models.Avg('rating'),
				total_reviews=models.Count('id'),
				recent_avg_rating=models.Avg('rating', filter=models.Q(created_at__gte=recent_cutoff)),
				recent_reviews=models.Count('id', filter=models.Q(created_at__gte=recent_cutoff)),
			)
		)
		reviews_by_product = {
			int(row['product_id']): row
			for row in review_rows
		}
		weighted_rating_sum = 0.0
		weighted_rating_votes = 0
		for row in review_rows:
			votes = int(row.get('total_reviews') or 0)
			avg = _as_float(row.get('avg_rating'), 0.0)
			weighted_rating_sum += (avg * votes)
			weighted_rating_votes += votes
		if weighted_rating_votes > 0:
			global_average = weighted_rating_sum / weighted_rating_votes

	interactions_by_product = {}
	if product_ids:
		interaction_rows = (
			InteractionLog.objects.filter(
				product_id__in=product_ids,
				timestamp__gte=week_cutoff,
			)
			.values('product_id')
			.annotate(
				recent_product_hits=models.Count(
					'id',
					filter=models.Q(action__in=['view', 'click'], timestamp__gte=recent_cutoff),
				),
				week_product_hits=models.Count('id', filter=models.Q(action__in=['view', 'click'])),
				recent_promo_hits=models.Count(
					'id',
					filter=models.Q(action='promotion_click', timestamp__gte=recent_cutoff),
				),
				week_promo_hits=models.Count('id', filter=models.Q(action='promotion_click')),
			)
		)
		interactions_by_product = {
			int(row['product_id']): row
			for row in interaction_rows
		}

	viewer_rows = (
		PromotionViewer.objects.filter(promotion_id__in=promotion_ids)
		.values('promotion_id')
		.annotate(
			recent_viewers=models.Count('id', filter=models.Q(last_seen_at__gte=recent_cutoff)),
			total_viewers=models.Count('id'),
		)
	)
	viewers_by_promotion = {
		int(row['promotion_id']): row
		for row in viewer_rows
	}

	ranked_entries = []
	for promo in candidates:
		interaction_stats = interactions_by_product.get(promo.product_id or -1, {})
		viewer_stats = viewers_by_promotion.get(promo.id, {})
		review_stats = reviews_by_product.get(promo.product_id or -1, {})

		discount_strength = _as_float(getattr(promo, 'percentage', 0.0), 0.0)
		product_recent_hits = int(interaction_stats.get('recent_product_hits') or 0)
		product_week_hits = int(interaction_stats.get('week_product_hits') or 0)
		promo_recent_hits = int(interaction_stats.get('recent_promo_hits') or 0)
		promo_week_hits = int(interaction_stats.get('week_promo_hits') or 0)
		recent_viewers = int(viewer_stats.get('recent_viewers') or 0)
		total_viewers = int(viewer_stats.get('total_viewers') or 0)

		total_reviews = int(review_stats.get('total_reviews') or 0)
		avg_rating = _as_float(review_stats.get('avg_rating'), global_average)
		rating_support = _bayesian_rating(
			avg_rating,
			total_reviews,
			global_average=global_average,
			minimum_votes=8.0,
		)

		engagement_raw = (
			(promo_recent_hits * 3.0)
			+ (promo_week_hits * 1.8)
			+ (recent_viewers * 2.0)
			+ (total_viewers * 0.35)
			+ (product_recent_hits * 1.4)
			+ (product_week_hits * 0.45)
		)
		engagement_score = math.log1p(max(engagement_raw, 0.0))
		freshness_score = _recency_boost(getattr(promo, 'created_at', None), now, horizon_hours=120)

		final_score = (
			(engagement_score * 6.6)
			+ (discount_strength * 1.35)
			+ (freshness_score * 4.2)
			+ (rating_support * 2.0)
		)
		has_signal = 1 if engagement_raw > 0 else 0
		ranked_entries.append((promo.id, has_signal, final_score, promo.created_at))

	ranked_entries.sort(key=lambda item: (item[1], item[2], item[3]), reverse=True)
	ranked_ids = [item[0] for item in ranked_entries]
	return _apply_ranked_order(queryset, ranked_ids)


def _rank_packs_for_home(queryset, request):
	if not _as_bool(request.query_params.get('home_rank')):
		return queryset

	now = timezone.now()
	window_hours = _as_positive_int(request.query_params.get('home_window_hours'), 168)
	candidate_limit = _as_positive_int(request.query_params.get('home_candidate_limit'), 300)
	recent_cutoff = now - timedelta(hours=window_hours)
	week_cutoff = now - timedelta(days=7)

	candidates = list(queryset.prefetch_related('pack_products')[:candidate_limit])
	if not candidates:
		return queryset

	pack_ids = [pack.id for pack in candidates]
	merchant_ids = [pack.merchant_id for pack in candidates if pack.merchant_id]

	merchant_reviews_by_store = {}
	global_average = 3.5
	if merchant_ids:
		merchant_review_rows = (
			Review.objects.filter(store_id__in=merchant_ids)
			.values('store_id')
			.annotate(
				avg_rating=models.Avg('rating'),
				total_reviews=models.Count('id'),
				recent_avg_rating=models.Avg('rating', filter=models.Q(created_at__gte=recent_cutoff)),
				recent_reviews=models.Count('id', filter=models.Q(created_at__gte=recent_cutoff)),
			)
		)
		merchant_reviews_by_store = {
			int(row['store_id']): row
			for row in merchant_review_rows
		}
		weighted_rating_sum = 0.0
		weighted_rating_votes = 0
		for row in merchant_review_rows:
			votes = int(row.get('total_reviews') or 0)
			avg = _as_float(row.get('avg_rating'), 0.0)
			weighted_rating_sum += (avg * votes)
			weighted_rating_votes += votes
		if weighted_rating_votes > 0:
			global_average = weighted_rating_sum / weighted_rating_votes

	pack_products_by_pack = {}
	all_product_ids = set()
	for pack in candidates:
		product_ids = []
		for pack_product in pack.pack_products.all():
			product_ids.append(pack_product.product_id)
			all_product_ids.add(pack_product.product_id)
		pack_products_by_pack[pack.id] = product_ids

	interactions_by_product = {}
	if all_product_ids:
		interaction_rows = (
			InteractionLog.objects.filter(
				product_id__in=list(all_product_ids),
				action__in=['view', 'click'],
				timestamp__gte=week_cutoff,
			)
			.values('product_id')
			.annotate(
				recent_hits=models.Count('id', filter=models.Q(timestamp__gte=recent_cutoff)),
				week_hits=models.Count('id'),
			)
		)
		interactions_by_product = {
			int(row['product_id']): row
			for row in interaction_rows
		}

	ranked_entries = []
	for pack in candidates:
		merchant_stats = merchant_reviews_by_store.get(pack.merchant_id or -1, {})
		total_reviews = int(merchant_stats.get('total_reviews') or 0)
		recent_reviews = int(merchant_stats.get('recent_reviews') or 0)
		avg_rating = _as_float(merchant_stats.get('avg_rating'), global_average)
		recent_avg = _as_float(merchant_stats.get('recent_avg_rating'), avg_rating)

		recent_rating_score = _bayesian_rating(
			recent_avg,
			recent_reviews,
			global_average=global_average,
			minimum_votes=2.0,
		)
		overall_rating_score = _bayesian_rating(
			avg_rating,
			total_reviews,
			global_average=global_average,
			minimum_votes=6.0,
		)
		rating_score = (
			(recent_rating_score * 0.75) + (overall_rating_score * 0.25)
			if recent_reviews > 0
			else overall_rating_score
		)

		pack_product_ids = pack_products_by_pack.get(pack.id, [])
		recent_hits = 0
		week_hits = 0
		for product_id in pack_product_ids:
			stats = interactions_by_product.get(product_id, {})
			recent_hits += int(stats.get('recent_hits') or 0)
			week_hits += int(stats.get('week_hits') or 0)

		popularity_score = math.log1p(max((recent_hits * 2) + week_hits, 0))
		review_volume_score = math.log1p(max((recent_reviews * 2) + total_reviews, 0))
		freshness_score = _recency_boost(getattr(pack, 'created_at', None), now, horizon_hours=144)
		size_bonus = min(len(pack_product_ids), 8) * 0.6

		final_score = (
			(rating_score * 15.5)
			+ (review_volume_score * 2.0)
			+ (popularity_score * 4.2)
			+ (freshness_score * 4.4)
			+ size_bonus
		)
		has_ratings = 1 if total_reviews > 0 else 0
		ranked_entries.append((pack.id, has_ratings, final_score, pack.created_at))

	ranked_entries.sort(key=lambda item: (item[1], item[2], item[3]), reverse=True)
	ranked_ids = [item[0] for item in ranked_entries]
	return _apply_ranked_order(queryset, ranked_ids)


def _build_discovery_meta(request, source):
	return {
		'source': source,
		'discovery_mode': request.query_params.get('discovery_mode') or (
			'nearby' if request.query_params.get('lat') and request.query_params.get('lng') else 'none'
		),
		'distance_km': request.query_params.get('radius_km') or request.query_params.get('distance_km'),
		'wilaya_code': request.query_params.get('wilaya_code'),
		'baladiya': request.query_params.get('baladiya'),
	}


def _log_product_list_impressions(request, products, source='product_list_request', max_items=24):
	if not getattr(request.user, 'is_authenticated', False):
		return
	try:
		from analytics.utils import log_user_event
		metadata = _build_discovery_meta(request, source)
		session_id = str(request.query_params.get('session_id') or '')
		for product in list(products)[:max_items]:
			log_user_event(
				request.user,
				'view',
				product=product,
				metadata=dict(metadata),
				session_id=session_id,
			)
	except Exception:
		pass


def _log_product_detail_click(request, product, source='product_detail_request'):
	if not getattr(request.user, 'is_authenticated', False):
		return
	try:
		from analytics.utils import log_user_event
		metadata = _build_discovery_meta(request, source)
		session_id = str(request.query_params.get('session_id') or '')
		log_user_event(
			request.user,
			'click',
			product=product,
			metadata=metadata,
			session_id=session_id,
		)
	except Exception:
		pass


def _validate_uploaded_image(image):
	validator = FileExtensionValidator(allowed_extensions=ALLOWED_EXTENSIONS)
	validator(image)
	if getattr(image, 'size', 0) > MAX_IMAGE_SIZE_BYTES:
		raise serializers.ValidationError('Image exceeds 5MB limit.')


def _trigger_new_post_notification(user, instance, post_type):
	"""Best-effort push notification for followers on new content."""
	try:
		from notifications.tasks import async_send_new_post_notification
		async_send_new_post_notification(
			store_id=user.id,
			post_id=instance.id,
			post_type=post_type,
			post_title=getattr(instance, 'name', ''),
		)
	except Exception as e:
		print(f"Failed to trigger push task for {post_type}: {e}")


class IsStoreOwner(permissions.BasePermission):
	def has_object_permission(self, request, view, obj):
		# Resolve "owner" across the unified domain model (store == users.User)
		# Supported objects: Product(store), Pack(merchant), Promotion(store),
		# ProductImage(product.store), PackImage(pack.merchant), PackProduct(pack.merchant),
		# PromotionImage(promotion.store)
		owner = getattr(obj, 'store', None) or getattr(obj, 'merchant', None)
		if owner is None:
			product = getattr(obj, 'product', None)
			if product is not None:
				owner = getattr(product, 'store', None)
			pack = getattr(obj, 'pack', None)
			if owner is None and pack is not None:
				owner = getattr(pack, 'merchant', None)
			promotion = getattr(obj, 'promotion', None)
			if owner is None and promotion is not None:
				owner = getattr(promotion, 'store', None)
		return request.user.is_superuser or (owner is not None and owner == request.user)


class CategoryViewSet(viewsets.ModelViewSet):
	queryset = Category.objects.all()
	serializer_class = CategorySerializer
	permission_classes = [permissions.IsAuthenticatedOrReadOnly]


class ProductViewSet(viewsets.ModelViewSet):
	# IMPORTANT: your Product model should now select_related('store', 'category')
	# (remove store__owner if you migrated away from Store model)
	queryset = Product.objects.select_related('store', 'category').prefetch_related('images')
	serializer_class = ProductSerializer
	# Enable filtering by store/category/status so profile pages only show the owner's products
	filter_backends = [filters.SearchFilter, filters.OrderingFilter, DjangoFilterBackend]
	search_fields = ['name', 'description', 'store__name', 'store__username', 'store__address']
	ordering_fields = ['created_at', 'price', 'average_rating']
	filterset_fields = ['store', 'category', 'available_status']

	def get_permissions(self):
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsStoreOwner()]
		return [permissions.IsAuthenticated()]

	def get_queryset(self):
		queryset = Product.objects.select_related('store', 'category').prefetch_related('images')
		store_id = self.request.query_params.get('store')
		if store_id:
			queryset = queryset.filter(store_id=store_id)

		# Support multi-category filtering from search tab
		category_ids_raw = (self.request.query_params.get('category_ids') or '').strip()
		if category_ids_raw:
			category_ids = []
			for raw_id in category_ids_raw.split(','):
				raw_id = raw_id.strip()
				if not raw_id:
					continue
				try:
					category_ids.append(int(raw_id))
				except (TypeError, ValueError):
					continue
			if category_ids:
				queryset = queryset.filter(category_id__in=category_ids)

		min_price = self.request.query_params.get('min_price')
		if min_price not in (None, ''):
			try:
				queryset = queryset.filter(price__gte=float(min_price))
			except (TypeError, ValueError):
				pass

		max_price = self.request.query_params.get('max_price')
		if max_price not in (None, ''):
			try:
				queryset = queryset.filter(price__lte=float(max_price))
			except (TypeError, ValueError):
				pass

		wilaya_code = (self.request.query_params.get('wilaya_code') or '').strip()
		baladiya = (self.request.query_params.get('baladiya') or '').strip()
		delivery_match = models.Q()
		if wilaya_code:
			delivery_match = models.Q(delivery_available=True) & (
				models.Q(delivery_wilayas__isnull=True)
				| models.Q(delivery_wilayas__exact='')
				| models.Q(delivery_wilayas__icontains=wilaya_code)
			)

		wilaya_scope_q = models.Q(store__address__icontains=wilaya_code)
		if wilaya_code:
			wilaya_scope_q |= delivery_match

		baladiya_scope_q = (
			models.Q(store__address__icontains=wilaya_code)
			& models.Q(store__address__icontains=baladiya)
		)
		if wilaya_code:
			baladiya_scope_q |= delivery_match

		baladiya_only_q = models.Q(store__address__icontains=baladiya)
		queryset = _apply_city_scope_with_baladiya_fallback(
			queryset=queryset,
			request=self.request,
			wilaya_code=wilaya_code,
			baladiya=baladiya,
			wilaya_scope_q=wilaya_scope_q,
			baladiya_scope_q=baladiya_scope_q,
			baladiya_only_q=baladiya_only_q,
		)

		ordering_param = (self.request.query_params.get('ordering') or '').strip()
		min_rating = self.request.query_params.get('min_rating')
		needs_rating_annotation = (
			(min_rating not in (None, '')) or ('average_rating' in ordering_param)
		)
		if needs_rating_annotation:
			queryset = queryset.annotate(average_rating=models.Avg('reviews__rating'))
			if min_rating not in (None, ''):
				try:
					queryset = queryset.filter(average_rating__gte=float(min_rating))
				except (TypeError, ValueError):
					pass
		
		# --- Advanced Search Logic (Academic) ---
		lat = self.request.query_params.get('lat')
		lng = self.request.query_params.get('lng')
		category_id = self.request.query_params.get('category')
		radius_override = self.request.query_params.get('radius_km')
		
		# Only apply if location is provided (Search Mode)
		if lat and lng:
			try:
				user_lat = float(lat)
				user_lng = float(lng)
				
				# 1. Adaptive Radius Calculation
				category = None
				if category_id:
					category = Category.objects.filter(id=category_id).first()
				
				radius_km = calculate_adaptive_radius(category)
				if radius_override not in (None, ''):
					try:
						radius_km = float(radius_override)
					except (TypeError, ValueError):
						pass
				
				# 2. Bounding Box Filter (Spatial Optimization)
				# 1 deg lat ~= 111 km
				# 1 deg lng ~= 111 km * cos(lat)
				lat_delta = radius_km / 111.0
				lng_divisor = 111.0 * abs(math.cos(math.radians(user_lat)))
				if lng_divisor < 0.0001:
					lng_divisor = 0.0001
				lng_delta = radius_km / lng_divisor
				
				queryset = queryset.filter(
					store__allow_nearby_visibility=True,
					store__latitude__isnull=False,
					store__longitude__isnull=False,
					store__latitude__range=(user_lat - lat_delta, user_lat + lat_delta),
					store__longitude__range=(user_lng - lng_delta, user_lng + lng_delta)
				)
				
				# 3. Weighted Ranking (Distance, Price, Reputation)
				queryset = apply_weighted_ranking(queryset, user_lat, user_lng)
				
			except (ValueError, TypeError):
				pass # Fallback to standard filtering

		queryset = queryset.distinct()
		queryset = _rank_products_for_home(queryset, self.request)

		return queryset

	def perform_create(self, serializer):
		ensure_can_create_post(self.request.user, 'product')
		# Prevent store spoofing: the authenticated user IS the store
		instance = serializer.save(store=self.request.user)
		_trigger_new_post_notification(self.request.user, instance, 'product')

	def retrieve(self, request, *args, **kwargs):
		instance = self.get_object()
		_log_product_detail_click(request, instance)
		serializer = self.get_serializer(instance)
		return Response(serializer.data)

	def list(self, request, *args, **kwargs):
		queryset = self.filter_queryset(self.get_queryset())
		page = self.paginate_queryset(queryset)

		if page is not None:
			serializer = self.get_serializer(page, many=True)
			response = self.get_paginated_response(serializer.data)
			_log_product_list_impressions(request, page)
			return response

		serializer = self.get_serializer(queryset, many=True)
		data = serializer.data
		_log_product_list_impressions(request, list(queryset[:24]))
		return Response(data)


class ProductImageViewSet(viewsets.ModelViewSet):
	queryset = ProductImage.objects.select_related('product', 'product__store')
	serializer_class = ProductImageSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_permissions(self):
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsStoreOwner()]
		return super().get_permissions()

	def perform_create(self, serializer):
		product = serializer.validated_data.get('product')
		image = serializer.validated_data.get('image')
		if image is not None:
			_validate_uploaded_image(image)
		if product is None or product.store != self.request.user:
			raise PermissionDenied('You can only add images to your own products')
		serializer.save()


class PackViewSet(viewsets.ModelViewSet):
	# IMPORTANT: your Pack model should now select_related('store') only
	queryset = Pack.objects.select_related('merchant').prefetch_related('images', 'pack_products').order_by('-created_at', '-id')
	serializer_class = PackSerializer
	filter_backends = [filters.SearchFilter, filters.OrderingFilter, DjangoFilterBackend]
	search_fields = ['name', 'description', 'merchant__name', 'merchant__username', 'merchant__address']
	ordering_fields = ['created_at', 'discount', 'merchant_rating']
	filterset_fields = ['merchant', 'available_status']

	def update(self, request, *args, **kwargs):
		# Treat PUT as partial update too (mobile clients often send only changed fields).
		kwargs['partial'] = True
		return super().update(request, *args, **kwargs)

	def get_permissions(self):
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsStoreOwner()]
		return [permissions.IsAuthenticated()]

	def get_queryset(self):
		queryset = super().get_queryset()
		store_id = self.request.query_params.get('store') or self.request.query_params.get('merchant')
		if store_id:
			queryset = queryset.filter(merchant_id=store_id)

		category_id = self.request.query_params.get('category')
		if category_id not in (None, ''):
			queryset = queryset.filter(pack_products__product__category_id=category_id)

		category_ids_raw = (self.request.query_params.get('category_ids') or '').strip()
		if category_ids_raw:
			category_ids = []
			for raw_id in category_ids_raw.split(','):
				raw_id = raw_id.strip()
				if not raw_id:
					continue
				try:
					category_ids.append(int(raw_id))
				except (TypeError, ValueError):
					continue
			if category_ids:
				queryset = queryset.filter(pack_products__product__category_id__in=category_ids)

		min_price = self.request.query_params.get('min_price')
		if min_price not in (None, ''):
			try:
				queryset = queryset.filter(discount__gte=float(min_price))
			except (TypeError, ValueError):
				pass

		max_price = self.request.query_params.get('max_price')
		if max_price not in (None, ''):
			try:
				queryset = queryset.filter(discount__lte=float(max_price))
			except (TypeError, ValueError):
				pass

		wilaya_code = (self.request.query_params.get('wilaya_code') or '').strip()
		baladiya = (self.request.query_params.get('baladiya') or '').strip()
		delivery_match = models.Q()
		if wilaya_code:
			delivery_match = models.Q(delivery_available=True) & (
				models.Q(delivery_wilayas__isnull=True)
				| models.Q(delivery_wilayas__exact='')
				| models.Q(delivery_wilayas__icontains=wilaya_code)
			)

		wilaya_scope_q = models.Q(merchant__address__icontains=wilaya_code)
		if wilaya_code:
			wilaya_scope_q |= delivery_match

		baladiya_scope_q = (
			models.Q(merchant__address__icontains=wilaya_code)
			& models.Q(merchant__address__icontains=baladiya)
		)
		if wilaya_code:
			baladiya_scope_q |= delivery_match

		baladiya_only_q = models.Q(merchant__address__icontains=baladiya)
		queryset = _apply_city_scope_with_baladiya_fallback(
			queryset=queryset,
			request=self.request,
			wilaya_code=wilaya_code,
			baladiya=baladiya,
			wilaya_scope_q=wilaya_scope_q,
			baladiya_scope_q=baladiya_scope_q,
			baladiya_only_q=baladiya_only_q,
		)

		ordering_param = (self.request.query_params.get('ordering') or '').strip()
		min_rating = self.request.query_params.get('min_rating')
		needs_rating_annotation = (
			(min_rating not in (None, '')) or ('merchant_rating' in ordering_param)
		)
		if needs_rating_annotation:
			queryset = queryset.annotate(
				merchant_rating=models.Avg('merchant__store_reviews__rating')
			)
			if min_rating not in (None, ''):
				try:
					queryset = queryset.filter(merchant_rating__gte=float(min_rating))
				except (TypeError, ValueError):
					pass

		lat = self.request.query_params.get('lat')
		lng = self.request.query_params.get('lng')
		radius_km = self.request.query_params.get('radius_km')
		if lat not in (None, '') and lng not in (None, '') and radius_km not in (None, ''):
			try:
				user_lat = float(lat)
				user_lng = float(lng)
				radius = float(radius_km)
				lat_delta = radius / 111.0
				lng_divisor = 111.0 * abs(math.cos(math.radians(user_lat)))
				if lng_divisor < 0.0001:
					lng_divisor = 0.0001
				lng_delta = radius / lng_divisor
				queryset = queryset.filter(
					merchant__allow_nearby_visibility=True,
					merchant__latitude__isnull=False,
					merchant__longitude__isnull=False,
					merchant__latitude__range=(user_lat - lat_delta, user_lat + lat_delta),
					merchant__longitude__range=(user_lng - lng_delta, user_lng + lng_delta),
				)
			except (TypeError, ValueError):
				pass

		queryset = queryset.distinct()
		queryset = _rank_packs_for_home(queryset, self.request)
		return queryset

	def perform_create(self, serializer):
		ensure_can_create_post(self.request.user, 'pack')
		# Prevent merchant_id spoofing
		instance = serializer.save(merchant=self.request.user)
		_trigger_new_post_notification(self.request.user, instance, 'pack')


class PackProductViewSet(viewsets.ModelViewSet):
	queryset = PackProduct.objects.select_related('pack', 'pack__merchant', 'product')
	serializer_class = PackProductSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_permissions(self):
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsStoreOwner()]
		return super().get_permissions()

	def perform_create(self, serializer):
		pack = serializer.validated_data.get('pack')
		product = serializer.validated_data.get('product')
		if pack is None or product is None:
			raise PermissionDenied('Invalid pack/product')
		if pack.merchant != self.request.user:
			raise PermissionDenied('You can only modify your own packs')
		if product.store != self.request.user:
			raise PermissionDenied('Pack products must belong to the merchant')
		serializer.save()


class PackImageViewSet(viewsets.ModelViewSet):
	queryset = PackImage.objects.select_related('pack', 'pack__merchant')
	serializer_class = PackImageSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_permissions(self):
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsStoreOwner()]
		return super().get_permissions()

	def perform_create(self, serializer):
		pack = serializer.validated_data.get('pack')
		image = serializer.validated_data.get('image')
		if image is not None:
			_validate_uploaded_image(image)
		if pack is None or pack.merchant != self.request.user:
			raise PermissionDenied('You can only add images to your own packs')
		serializer.save()


class IsReviewOwner(permissions.BasePermission):
	"""Only allow review owners to edit/delete their reviews."""
	def has_object_permission(self, request, view, obj):
		if request.method in permissions.SAFE_METHODS:
			return True
		return obj.user == request.user


class ReviewViewSet(viewsets.ModelViewSet):
	queryset = Review.objects.select_related('user', 'store', 'product')
	serializer_class = ReviewSerializer
	filter_backends = [filters.OrderingFilter]
	ordering_fields = ['created_at']

	# KEEP ONLY ONE get_permissions (delete the duplicate one further down)
	def get_permissions(self):
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsReviewOwner()]
		return [permissions.IsAuthenticated()]

	def get_throttles(self):
		if self.action in ['create', 'rate_store']:
			self.throttle_scope = 'review_create'
			return [ScopedRateThrottle()]
		return super().get_throttles()

	def get_queryset(self):
		queryset = super().get_queryset()
		product_id = self.request.query_params.get('product')
		store_id = self.request.query_params.get('store')

		if store_id:
			queryset = queryset.filter(store_id=store_id)

		if product_id:
			try:
				Product.objects.only('id').get(id=product_id)
				# Product page should show reviews linked to this product only.
				queryset = queryset.filter(product_id=product_id)
			except Product.DoesNotExist:
				# If product doesn't exist, return empty set instead of 500.
				return queryset.none()

		return queryset

	def perform_create(self, serializer):
		store_id = self.request.data.get('store')
		product_id = self.request.data.get('product')

		store = None
		product = None

		# Product review path: derive store from product and keep review linked to product.
		if product_id not in (None, ''):
			try:
				product = Product.objects.select_related('store').get(id=product_id)
			except Product.DoesNotExist:
				raise serializers.ValidationError({'product': 'Product not found'})
			store = product.store

			# If store is also provided, it must match the product owner.
			if store_id not in (None, '') and str(store_id) != str(store.id):
				raise serializers.ValidationError({
					'store': 'Provided store does not match product store'
				})

		# Store review path.
		if store is None:
			if store_id in (None, ''):
				raise serializers.ValidationError({'store': 'store or product is required'})
			try:
				store = User.objects.get(id=store_id)
			except User.DoesNotExist:
				raise serializers.ValidationError({'store': 'Store not found'})

		defaults = dict(serializer.validated_data)
		defaults.pop('user', None)
		defaults.pop('store', None)
		defaults.pop('product', None)
		defaults['store'] = store

		# Allow users to edit their existing review immediately, but keep a cooldown
		# against rapid-fire creation of a fresh review on the same target.
		existing_review = Review.objects.filter(
			user=self.request.user,
			product=product if product is not None else None,
			store=store,
		).first()
		if existing_review is not None:
			for field, value in defaults.items():
				setattr(existing_review, field, value)
			review = existing_review
			review.save()
		else:
			trust = TrustSettings.get_settings()
			cooldown_cutoff = timezone.now() - timedelta(minutes=int(trust.review_cooldown_minutes or 5))
			recent_existing = Review.objects.filter(
				user=self.request.user,
				product=product if product is not None else None,
				store=store,
				created_at__gte=cooldown_cutoff,
			).first()
			if recent_existing is not None:
				record_abuse_signal(
					actor=self.request.user,
					signal_type='review_spam',
					target_type='product' if product is not None else 'store',
					target_id=product.id if product is not None else store.id,
					metadata={'reason': 'cooldown_hit'},
				)
				raise serializers.ValidationError({'detail': 'Please wait before updating this review again.'})

			if product is not None:
				review, _created = Review.objects.update_or_create(
					user=self.request.user,
					product=product,
					defaults=defaults,
				)
			else:
				review, _created = Review.objects.update_or_create(
					user=self.request.user,
					store=store,
					product=None,
					defaults=defaults,
				)
		try:
			from analytics.utils import log_user_event
			meta = {
				'rating': review.rating,
				'search_query': str(self.request.data.get('search_query') or '').strip().lower(),
				'discovery_mode': self.request.data.get('discovery_mode'),
				'distance_km': self.request.data.get('distance_km'),
				'wilaya_code': self.request.data.get('wilaya_code'),
				'store_id': store.id if store else None,
			}
			log_user_event(
				self.request.user,
				'rate',
				product=product,
				metadata=meta,
				session_id=str(self.request.data.get('session_id') or ''),
			)
		except Exception:
			pass

		scored = score_review_credibility(
			user=self.request.user,
			store_id=store.id if store else None,
			product_id=product.id if product else None,
			rating=int(review.rating),
		)
		review.credibility_score = scored.score
		review.credibility_level = scored.level
		review.evidence_snapshot = scored.evidence_snapshot
		review.is_low_credibility = scored.is_low_credibility
		review.scored_at = timezone.now()
		review.save(
			update_fields=[
				'credibility_score',
				'credibility_level',
				'evidence_snapshot',
				'is_low_credibility',
				'scored_at',
			]
		)
		if scored.is_low_credibility:
			record_abuse_signal(
				actor=self.request.user,
				signal_type='review_spam',
				target_type='product' if product is not None else 'store',
				target_id=product.id if product is not None else store.id,
				metadata={'reason': 'low_credibility', 'score': scored.score},
			)
		if store is not None:
			try:
				evaluate_store_verification(store)
			except Exception:
				pass
		serializer.instance = review

	@action(detail=False, methods=['post'], url_path='rate-store')
	def rate_store(self, request):
		"""Rate a store/user directly (create or update store review)."""
		store_id = request.data.get('store')
		rating = request.data.get('rating')
		comment = request.data.get('comment', '')

		if not store_id or not rating:
			return Response({'error': 'store and rating are required'}, status=status.HTTP_400_BAD_REQUEST)

		try:
			from users.models import User
			store = User.objects.get(id=store_id)
		except User.DoesNotExist:
			return Response({'error': 'Store not found'}, status=status.HTTP_404_NOT_FOUND)

		# Create or update the store review
		review, created = Review.objects.update_or_create(
			user=request.user,
			store=store,
			product=None,
			defaults={'rating': rating, 'comment': comment}
		)
		try:
			from analytics.utils import log_user_event
			log_user_event(
				request.user,
				'rate',
				metadata={
					'rating': review.rating,
					'store_id': store.id,
					'discovery_mode': request.data.get('discovery_mode'),
					'wilaya_code': request.data.get('wilaya_code'),
					'distance_km': request.data.get('distance_km'),
				},
				session_id=str(request.data.get('session_id') or ''),
			)
		except Exception:
			pass

		serializer = self.get_serializer(review)
		return Response(
			{'status': 'created' if created else 'updated', 'review': serializer.data},
			status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
		)

	def my_store_rating(self, request, store_id=None):
		"""Get current user's rating for a store."""
		try:
			review = Review.objects.get(user=request.user, store_id=store_id, product=None)
			return Response({'rating': review.rating, 'comment': review.comment})
		except Review.DoesNotExist:
			return Response({'rating': 0, 'comment': ''})


class IsFavoriteOwner(permissions.BasePermission):
	"""Only allow favorite owners to delete their favorites."""
	def has_object_permission(self, request, view, obj):
		return obj.user == request.user


class FavoriteViewSet(viewsets.ModelViewSet):
	queryset = Favorite.objects.select_related('user', 'product', 'product__store', 'product__category').prefetch_related('product__images')
	serializer_class = FavoriteSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_queryset(self):
		# Users can only see their own favorites
		return super().get_queryset().filter(user=self.request.user)

	def get_permissions(self):
		if self.action == 'destroy':
			return [permissions.IsAuthenticated(), IsFavoriteOwner()]
		return [permissions.IsAuthenticated()]

	def perform_create(self, serializer):
		favorite = serializer.save(user=self.request.user)
		try:
			from analytics.utils import log_user_event
			log_user_event(
				self.request.user,
				'favorite',
				product=getattr(favorite, 'product', None),
				metadata={
					'discovery_mode': self.request.data.get('discovery_mode'),
					'distance_km': self.request.data.get('distance_km'),
					'wilaya_code': self.request.data.get('wilaya_code'),
					'search_query': str(self.request.data.get('search_query') or '').strip().lower(),
				},
				session_id=str(self.request.data.get('session_id') or ''),
			)
		except Exception:
			pass

	def create(self, request, *args, **kwargs):
		# Check if already favorited
		product_id = request.data.get('product')
		existing = Favorite.objects.filter(user=request.user, product_id=product_id).first()
		if existing:
			# Return existing favorite instead of error
			serializer = self.get_serializer(existing)
			return Response(serializer.data, status=status.HTTP_200_OK)
		return super().create(request, *args, **kwargs)

	@action(detail=False, methods=['post'], url_path='toggle')
	def toggle(self, request):
		"""Toggle favorite status for a product."""
		product_id = request.data.get('product')
		if not product_id:
			return Response({'error': 'product is required'}, status=status.HTTP_400_BAD_REQUEST)

		try:
			product = Product.objects.get(id=product_id)
		except Product.DoesNotExist:
			return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)

		favorite, created = Favorite.objects.get_or_create(user=request.user, product=product)
		if not created:
			# Already exists, so remove it
			favorite.delete()
			return Response({'status': 'removed', 'is_favorited': False}, status=status.HTTP_200_OK)

		try:
			from analytics.utils import log_user_event
			log_user_event(
				request.user,
				'favorite',
				product=product,
				metadata={
					'discovery_mode': request.data.get('discovery_mode'),
					'distance_km': request.data.get('distance_km'),
					'wilaya_code': request.data.get('wilaya_code'),
					'search_query': str(request.data.get('search_query') or '').strip().lower(),
				},
				session_id=str(request.data.get('session_id') or ''),
			)
		except Exception:
			pass

		serializer = self.get_serializer(favorite)
		return Response({'status': 'added', 'is_favorited': True, 'favorite': serializer.data}, status=status.HTTP_201_CREATED)

	@action(detail=False, methods=['get'], url_path='check/(?P<product_id>[^/.]+)')
	def check(self, request, product_id=None):
		"""Check if a product is favorited by the current user."""
		is_favorited = Favorite.objects.filter(user=request.user, product_id=product_id).exists()
		return Response({'is_favorited': is_favorited})


class IsStoreOwnerOrReadOnly(permissions.BasePermission):
	def has_object_permission(self, request, view, obj):
		if request.method in permissions.SAFE_METHODS:
			return True
		return request.user.is_superuser or obj.store == request.user


class PromotionViewSet(viewsets.ModelViewSet):
	queryset = Promotion.objects.select_related('store', 'product').prefetch_related('images')
	serializer_class = PromotionSerializer
	filter_backends = [filters.SearchFilter, filters.OrderingFilter, DjangoFilterBackend]
	search_fields = ['name', 'description', 'product__name', 'product__description', 'store__name', 'store__username']
	ordering_fields = ['created_at', 'percentage', 'product_rating', 'product__price']

	def get_permissions(self):
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsStoreOwnerOrReadOnly()]
		return [permissions.IsAuthenticated()]

	def get_queryset(self):
		qs = super().get_queryset()
		now = timezone.now()
		store_id = self.request.query_params.get('store')
		include_inactive_raw = str(
			self.request.query_params.get('include_inactive', 'false')
		).lower()
		include_inactive = include_inactive_raw in ['1', 'true', 'yes', 'on']

		# Owner-only bypass for profile/history screens.
		allow_include_inactive = False
		if include_inactive and store_id and self.request.user.is_authenticated:
			try:
				allow_include_inactive = int(store_id) == int(self.request.user.id)
			except Exception:
				allow_include_inactive = False
		
		print(f"\n[PROMOTION_TIME_DEBUG] Server current time: {now} (ISO: {now.isoformat()})")
		print(
			f"[PROMOTION_TIME_DEBUG] Request params: store={store_id}, include_inactive={include_inactive}, owner_override={allow_include_inactive}"
		)
		
		if self.action in ['list', 'retrieve']:
			if not allow_include_inactive:
				qs = qs.filter(
					is_active=True,
				).filter(
					# null start_date means starts immediately
					models.Q(start_date__isnull=True) | models.Q(start_date__lte=now)
				).filter(
					# null end_date means open-ended promotion
					models.Q(end_date__isnull=True) | models.Q(end_date__gte=now)
				)
				
				# Debug: Log all promotions (filtered and unfiltered)
				all_promos = super().get_queryset().filter(is_active=True).order_by('-created_at')
				print(f"[PROMOTION_TIME_DEBUG] Total active promotions: {all_promos.count()}")
				for p in all_promos[:10]:
					status = "✓ SHOWING" if qs.filter(id=p.id).exists() else "✗ HIDDEN"
					print(f"[PROMOTION_TIME_DEBUG]   Promo #{p.id}: start={p.start_date}, end={p.end_date}, created={p.created_at} → {status}")
			else:
				print("[PROMOTION_TIME_DEBUG] Owner include_inactive override enabled: returning promotions regardless of schedule window")
		
		if store_id:
			qs = qs.filter(store_id=store_id)
		
		product_id = self.request.query_params.get('product')
		if product_id:
			qs = qs.filter(product_id=product_id)

		category_id = self.request.query_params.get('category')
		if category_id not in (None, ''):
			qs = qs.filter(product__category_id=category_id)

		category_ids_raw = (self.request.query_params.get('category_ids') or '').strip()
		if category_ids_raw:
			category_ids = []
			for raw_id in category_ids_raw.split(','):
				raw_id = raw_id.strip()
				if not raw_id:
					continue
				try:
					category_ids.append(int(raw_id))
				except (TypeError, ValueError):
					continue
			if category_ids:
				qs = qs.filter(product__category_id__in=category_ids)

		min_price = self.request.query_params.get('min_price')
		if min_price not in (None, ''):
			try:
				qs = qs.filter(product__price__gte=float(min_price))
			except (TypeError, ValueError):
				pass

		max_price = self.request.query_params.get('max_price')
		if max_price not in (None, ''):
			try:
				qs = qs.filter(product__price__lte=float(max_price))
			except (TypeError, ValueError):
				pass

		wilaya_code = (self.request.query_params.get('wilaya_code') or '').strip()
		baladiya = (self.request.query_params.get('baladiya') or '').strip()
		address_wilaya_q = (
			models.Q(product__store__address__icontains=wilaya_code)
			| models.Q(store__address__icontains=wilaya_code)
		)
		address_baladiya_q = (
			models.Q(product__store__address__icontains=baladiya)
			| models.Q(store__address__icontains=baladiya)
		)

		delivery_match = models.Q()
		if wilaya_code:
			delivery_match = models.Q(product__delivery_available=True) & (
				models.Q(product__delivery_wilayas__isnull=True)
				| models.Q(product__delivery_wilayas__exact='')
				| models.Q(product__delivery_wilayas__icontains=wilaya_code)
			)

		wilaya_scope_q = address_wilaya_q
		if wilaya_code:
			wilaya_scope_q |= delivery_match

		baladiya_scope_q = address_wilaya_q & address_baladiya_q
		if wilaya_code:
			baladiya_scope_q |= delivery_match

		baladiya_only_q = address_baladiya_q
		qs = _apply_city_scope_with_baladiya_fallback(
			queryset=qs,
			request=self.request,
			wilaya_code=wilaya_code,
			baladiya=baladiya,
			wilaya_scope_q=wilaya_scope_q,
			baladiya_scope_q=baladiya_scope_q,
			baladiya_only_q=baladiya_only_q,
		)

		ordering_param = (self.request.query_params.get('ordering') or '').strip()
		min_rating = self.request.query_params.get('min_rating')
		needs_rating_annotation = (
			(min_rating not in (None, '')) or ('product_rating' in ordering_param)
		)
		if needs_rating_annotation:
			qs = qs.annotate(product_rating=models.Avg('product__reviews__rating'))
			if min_rating not in (None, ''):
				try:
					qs = qs.filter(product_rating__gte=float(min_rating))
				except (TypeError, ValueError):
					pass

		lat = self.request.query_params.get('lat')
		lng = self.request.query_params.get('lng')
		radius_km = self.request.query_params.get('radius_km')
		if lat not in (None, '') and lng not in (None, '') and radius_km not in (None, ''):
			try:
				user_lat = float(lat)
				user_lng = float(lng)
				radius = float(radius_km)
				lat_delta = radius / 111.0
				lng_divisor = 111.0 * abs(math.cos(math.radians(user_lat)))
				if lng_divisor < 0.0001:
					lng_divisor = 0.0001
				lng_delta = radius / lng_divisor
				qs = qs.filter(
					product__store__allow_nearby_visibility=True,
					product__store__latitude__isnull=False,
					product__store__longitude__isnull=False,
					product__store__latitude__range=(user_lat - lat_delta, user_lat + lat_delta),
					product__store__longitude__range=(user_lng - lng_delta, user_lng + lng_delta),
				)
			except (TypeError, ValueError):
				pass
		
		qs = qs.distinct()
		qs = _rank_promotions_for_home(qs, self.request)
		return qs

	def perform_create(self, serializer):
		ensure_can_create_post(self.request.user, 'promotion')
		start_date = serializer.validated_data.get('start_date')
		end_date = serializer.validated_data.get('end_date')
		
		# Debug logging for time validation
		now = timezone.now()
		print(f'[PROMOTION_CREATE] ======================================')
		print(f'[PROMOTION_CREATE] Server current time: {now}')
		print(f'[PROMOTION_CREATE] Server time ISO: {now.isoformat()}')
		print(f'[PROMOTION_CREATE] Start Date: {start_date}')
		if start_date:
			print(f'[PROMOTION_CREATE] Start Date ISO: {start_date.isoformat()}')
			diff = start_date - now
			print(f'[PROMOTION_CREATE] Status vs server: {("starts in future" if diff.total_seconds() > 0 else "already started")}')
			print(f'[PROMOTION_CREATE] Time diff: {diff.total_seconds()} seconds')
		else:
			print(f'[PROMOTION_CREATE] Start Date: None (starts immediately)')
		print(f'[PROMOTION_CREATE] End Date: {end_date}')
		if end_date:
			print(f'[PROMOTION_CREATE] End Date ISO: {end_date.isoformat()}')
			diff = end_date - now
			print(f'[PROMOTION_CREATE] Status vs server: {("expires in future" if diff.total_seconds() > 0 else "already expired")}')
			print(f'[PROMOTION_CREATE] Time diff: {diff.total_seconds()} seconds')
		else:
			print(f'[PROMOTION_CREATE] End Date: None (no expiry)')
		print(f'[PROMOTION_CREATE] ======================================')
		
		enforce_promotion_constraints(
			self.request.user,
			start_date=start_date,
			end_date=end_date,
			kind='promotion',
		)
		instance = serializer.save(store=self.request.user)
		_trigger_new_post_notification(self.request.user, instance, 'promotion')

	def perform_update(self, serializer):
		start_date = serializer.validated_data.get('start_date', serializer.instance.start_date)
		end_date = serializer.validated_data.get('end_date', serializer.instance.end_date)
		features = enforce_promotion_constraints(
			self.request.user,
			start_date=start_date,
			end_date=end_date,
			promotion_id=serializer.instance.id,
			kind='promotion',
		)
		serializer.save()


class PromotionImageViewSet(viewsets.ModelViewSet):
	queryset = PromotionImage.objects.select_related('promotion')
	serializer_class = PromotionImageSerializer
	permission_classes = [permissions.IsAuthenticated, IsStoreOwner]

	def perform_create(self, serializer):
		promotion = serializer.validated_data.get('promotion')
		image = serializer.validated_data.get('image')
		if image is not None:
			_validate_uploaded_image(image)
		if promotion is None or promotion.store != self.request.user:
			raise PermissionDenied('You can only add images to your own promotions')
		serializer.save()


class ProductReportViewSet(viewsets.ModelViewSet):
	serializer_class = ProductReportSerializer
	permission_classes = [permissions.IsAuthenticated]
	throttle_classes = [ScopedRateThrottle]

	def get_throttles(self):
		if self.action == 'create':
			self.throttle_scope = 'report_create'
			return [ScopedRateThrottle()]
		return super().get_throttles()

	def get_queryset(self):
		user = self.request.user
		if user.is_superuser or user.is_staff:
			return ProductReport.objects.select_related('reporter', 'product', 'product__store').all()
		return ProductReport.objects.select_related('reporter', 'product', 'product__store').filter(reporter=user)

	def perform_create(self, serializer):
		product = serializer.validated_data.get('product')
		trust = TrustSettings.get_settings()
		cutoff = timezone.now() - timedelta(minutes=int(trust.report_cooldown_minutes or 10))
		if ProductReport.objects.filter(reporter=self.request.user, product=product, created_at__gte=cutoff).exists():
			record_abuse_signal(
				actor=self.request.user,
				signal_type='report_spam',
				target_type='product',
				target_id=product.id,
				metadata={'reason': 'cooldown_hit'},
			)
			raise serializers.ValidationError({'detail': 'Please wait before submitting another report for this product.'})

		reports_today = ProductReport.objects.filter(
			reporter=self.request.user,
			created_at__date=timezone.now().date(),
		).count()
		if reports_today >= int(trust.max_reports_per_day or 20):
			record_abuse_signal(
				actor=self.request.user,
				signal_type='report_spam',
				target_type='account',
				target_id=self.request.user.id,
				metadata={'reason': 'daily_cap_hit', 'reports_today': reports_today},
			)
			raise serializers.ValidationError({'detail': 'Daily report limit reached. Try again tomorrow.'})

		scored = score_product_report(
			reporter=self.request.user,
			product_id=product.id,
			store_id=product.store_id,
		)
		serializer.save(
			reporter=self.request.user,
			seriousness_score=scored.score,
			seriousness_level=scored.level,
			evidence_snapshot=scored.evidence_snapshot,
			is_low_credibility=scored.is_low_credibility,
			reporter_reputation_score_at_submission=scored.reporter_reputation,
			scored_at=timezone.now(),
		)
		if scored.is_low_credibility:
			record_abuse_signal(
				actor=self.request.user,
				signal_type='low_cred_report',
				target_type='product',
				target_id=product.id,
				metadata={'score': scored.score},
			)
