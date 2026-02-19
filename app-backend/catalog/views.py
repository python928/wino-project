from django.db import models
from rest_framework import filters, permissions, viewsets, status, serializers
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend

from .models import Category, Pack, PackImage, PackProduct, Product, ProductImage, Review, Favorite, Promotion, PromotionImage
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
)
from users.models import User

# NOTE: Store == users.User now (unified profile)


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
		# No role-based filtering anymore
		return queryset

	def perform_create(self, serializer):
		# Prevent store spoofing: the authenticated user IS the store
		serializer.save(store=self.request.user)

	def retrieve(self, request, *args, **kwargs):
		instance = self.get_object()
		if request.user.is_authenticated:
			try:
				from analytics.utils import log_user_event
				log_user_event(request.user, 'view', product=instance)
			except Exception:
				pass
		serializer = self.get_serializer(instance)
		return Response(serializer.data)

	def list(self, request, *args, **kwargs):
		response = super().list(request, *args, **kwargs)
		if request.user.is_authenticated:
			try:
				from analytics.utils import log_user_event
				params = request.query_params
				keyword = params.get('search', '').strip()
				if keyword:
					log_user_event(request.user, 'search', metadata={'keyword': keyword.lower()})
				min_price = params.get('min_price')
				max_price = params.get('max_price')
				if min_price or max_price:
					meta = {}
					try:
						if min_price:
							meta['min'] = float(min_price)
						if max_price:
							meta['max'] = float(max_price)
					except (ValueError, TypeError):
						pass
					if meta:
						log_user_event(request.user, 'filter_price', metadata=meta)
			except Exception:
				pass
		return response


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
		# Prevent merchant_id spoofing
		serializer.save(merchant=self.request.user)


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
			# If your app is "store review" (UNIQUE user+store), still show them on product pages.
			try:
				p = Product.objects.select_related('store').get(id=product_id)
				queryset = queryset.filter(
					models.Q(product_id=product_id) |
					models.Q(product__isnull=True, store_id=p.store_id)
				).distinct()
			except Product.DoesNotExist:
				# If product doesn't exist, return empty set instead of 500.
				return queryset.none()

		return queryset

	def perform_create(self, serializer):
		store_id = self.request.data.get('store')
		product_id = self.request.data.get('product')

		store = None

		# Allow creating/updating a store review from product page by passing product only.
		if (store_id is None or store_id == '') and product_id not in (None, ''):
			try:
				p = Product.objects.select_related('store').get(id=product_id)
			except Product.DoesNotExist:
				raise serializers.ValidationError({'product': 'Product not found'})
			store = p.store

		# Normal path: store is explicitly provided.
		if store is None:
			if store_id in (None, ''):
				raise serializers.ValidationError({'store': 'store is required'})
			try:
				store = User.objects.get(id=store_id)
			except User.DoesNotExist:
				raise serializers.ValidationError({'store': 'Store not found'})

		# UNIQUE(user, store) => create-or-update (no IntegrityError).
		defaults = dict(serializer.validated_data)
		defaults.pop('user', None)
		defaults.pop('store', None)

		# Keep reviews store-level (product nullable) to match the UNIQUE(user, store) constraint.
		defaults['product'] = None

		review, _created = Review.objects.update_or_create(
			user=self.request.user,
			store=store,
			defaults=defaults,
		)
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

	def perform_create(self, serializer):
		serializer.save(store=self.request.user)


class PromotionImageViewSet(viewsets.ModelViewSet):
	queryset = PromotionImage.objects.select_related('promotion')
	serializer_class = PromotionImageSerializer
	permission_classes = [permissions.IsAuthenticated, IsStoreOwner]

	def perform_create(self, serializer):
		promotion = serializer.validated_data.get('promotion')
		if promotion is None or promotion.store != self.request.user:
			raise PermissionDenied('You can only add images to your own promotions')
		serializer.save()
