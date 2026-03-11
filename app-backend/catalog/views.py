from django.db import models
from django.db.models import F
from django.utils import timezone
from rest_framework import filters, permissions, viewsets, status, serializers
import math
from .search_engine import calculate_adaptive_radius, apply_weighted_ranking
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend

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
from users.models import User
from subscriptions.services import ensure_can_create_post, enforce_promotion_constraints

# NOTE: Store == users.User now (unified profile)


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
	search_fields = ['name', 'description']
	ordering_fields = ['created_at', 'price']
	filterset_fields = ['store', 'category', 'available_status']

	def get_permissions(self):
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsStoreOwner()]
		return [permissions.IsAuthenticated()]

	def get_queryset(self):
		queryset = Product.objects.all()
		store_id = self.request.query_params.get('store')
		if store_id:
			queryset = queryset.filter(store_id=store_id)
		
		# --- Advanced Search Logic (Academic) ---
		lat = self.request.query_params.get('lat')
		lng = self.request.query_params.get('lng')
		category_id = self.request.query_params.get('category')
		
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
				
				# 2. Bounding Box Filter (Spatial Optimization)
				# 1 deg lat ~= 111 km
				# 1 deg lng ~= 111 km * cos(lat)
				lat_delta = radius_km / 111.0
				lng_delta = radius_km / (111.0 * abs(math.cos(math.radians(user_lat))))
				
				queryset = queryset.filter(
					store__latitude__range=(user_lat - lat_delta, user_lat + lat_delta),
					store__longitude__range=(user_lng - lng_delta, user_lng + lng_delta)
				)
				
				# 3. Weighted Ranking (Distance, Price, Reputation)
				queryset = apply_weighted_ranking(queryset, user_lat, user_lng)
				
			except (ValueError, TypeError):
				pass # Fallback to standard filtering
				
		return queryset

	def perform_create(self, serializer):
		ensure_can_create_post(self.request.user)
		# Prevent store spoofing: the authenticated user IS the store
		instance = serializer.save(store=self.request.user)
		_trigger_new_post_notification(self.request.user, instance, 'product')

	def retrieve(self, request, *args, **kwargs):
		instance = self.get_object()
		serializer = self.get_serializer(instance)
		return Response(serializer.data)

	def list(self, request, *args, **kwargs):
		return super().list(request, *args, **kwargs)


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
		if product is None or product.store != self.request.user:
			raise PermissionDenied('You can only add images to your own products')
		serializer.save()


class PackViewSet(viewsets.ModelViewSet):
	# IMPORTANT: your Pack model should now select_related('store') only
	queryset = Pack.objects.select_related('merchant').prefetch_related('images', 'pack_products')
	serializer_class = PackSerializer
	filter_backends = [filters.OrderingFilter, DjangoFilterBackend]
	ordering_fields = ['created_at', 'discount']
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
		return queryset

	def perform_create(self, serializer):
		ensure_can_create_post(self.request.user)
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

		# Enforce one review per user per product (when product is provided),
		# otherwise one review per user per store.
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
		serializer.save(user=self.request.user)

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
	filter_backends = [filters.OrderingFilter]
	ordering_fields = ['start_date', 'end_date', 'percentage']

	def get_permissions(self):
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsStoreOwnerOrReadOnly()]
		return [permissions.IsAuthenticated()]

	def get_queryset(self):
		qs = super().get_queryset()
		now = timezone.now()
		if self.action in ['list', 'retrieve']:
			qs = qs.filter(
				is_active=True,
				start_date__lte=now,
				end_date__gte=now,
			).filter(
				models.Q(max_impressions__isnull=True)
				| models.Q(unique_viewers_count__lt=F('max_impressions'))
			)
		store_id = self.request.query_params.get('store')
		if store_id:
			qs = qs.filter(store_id=store_id)
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

	def _register_impressions(self, request, promotion_ids):
		if not promotion_ids:
			return
		viewer_key = self._resolve_viewer_key(request)
		promotions = Promotion.objects.filter(id__in=promotion_ids).only('id', 'store_id', 'max_impressions')
		for promo in promotions:
			# Do not count store owner self-views.
			if getattr(request.user, 'is_authenticated', False) and request.user.id == promo.store_id:
				continue
			obj, created = PromotionViewer.objects.get_or_create(
				promotion_id=promo.id,
				viewer_key=viewer_key,
			)
			if not created:
				obj.save(update_fields=['last_seen_at'])
				continue
			Promotion.objects.filter(id=promo.id).update(unique_viewers_count=F('unique_viewers_count') + 1)

		# Auto-disable promotions that reached audience limit.
		Promotion.objects.filter(
			id__in=promotion_ids,
			max_impressions__isnull=False,
			unique_viewers_count__gte=F('max_impressions'),
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
		promo_id = None
		if isinstance(response.data, dict):
			promo_id = response.data.get('id')
		if promo_id:
			self._register_impressions(request, [promo_id])
		return response

	def perform_create(self, serializer):
		ensure_can_create_post(self.request.user)
		start_date = serializer.validated_data.get('start_date')
		end_date = serializer.validated_data.get('end_date')
		features = enforce_promotion_constraints(
			self.request.user,
			start_date=start_date,
			end_date=end_date,
		)
		max_impressions = serializer.validated_data.get('max_impressions')
		if max_impressions in (None, ''):
			max_impressions = features.get('promotion_max_impressions')
		instance = serializer.save(store=self.request.user, max_impressions=max_impressions)
		_trigger_new_post_notification(self.request.user, instance, 'promotion')

	def perform_update(self, serializer):
		start_date = serializer.validated_data.get('start_date', serializer.instance.start_date)
		end_date = serializer.validated_data.get('end_date', serializer.instance.end_date)
		features = enforce_promotion_constraints(
			self.request.user,
			start_date=start_date,
			end_date=end_date,
			promotion_id=serializer.instance.id,
		)
		max_impressions = serializer.validated_data.get('max_impressions', serializer.instance.max_impressions)
		plan_limit = features.get('promotion_max_impressions')
		if plan_limit and max_impressions and int(max_impressions) > int(plan_limit):
			raise serializers.ValidationError(
				{'max_impressions': f'Max impressions exceeds your plan limit ({plan_limit}).'}
			)
		serializer.save()


class PromotionImageViewSet(viewsets.ModelViewSet):
	queryset = PromotionImage.objects.select_related('promotion')
	serializer_class = PromotionImageSerializer
	permission_classes = [permissions.IsAuthenticated, IsStoreOwner]

	def perform_create(self, serializer):
		promotion = serializer.validated_data.get('promotion')
		if promotion is None or promotion.store != self.request.user:
			raise PermissionDenied('You can only add images to your own promotions')
		serializer.save()


class ProductReportViewSet(viewsets.ModelViewSet):
	serializer_class = ProductReportSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_queryset(self):
		user = self.request.user
		if user.is_superuser or user.is_staff:
			return ProductReport.objects.select_related('reporter', 'product', 'product__store').all()
		return ProductReport.objects.select_related('reporter', 'product', 'product__store').filter(reporter=user)

	def perform_create(self, serializer):
		serializer.save(reporter=self.request.user)
