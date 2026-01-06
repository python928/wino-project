from django.db import models
from rest_framework import filters, permissions, viewsets

from .models import Promotion, PromotionImage
from .serializers import PromotionImageSerializer, PromotionSerializer


class IsStoreOwner(permissions.BasePermission):
	def has_object_permission(self, request, view, obj):
		return request.user.is_superuser or obj.store.owner == request.user


class PromotionViewSet(viewsets.ModelViewSet):
	queryset = Promotion.objects.select_related('store', 'store__owner', 'product').prefetch_related('images')
	serializer_class = PromotionSerializer
	filter_backends = [filters.OrderingFilter]
	ordering_fields = ['start_date', 'end_date', 'percentage']

	def get_permissions(self):
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsStoreOwner()]
		return [permissions.IsAuthenticated()]

	def get_queryset(self):
		queryset = super().get_queryset()
		# For list/retrieve actions, only show promotions from active stores (owner role = STORE)
		if self.action in ['list', 'retrieve']:
			if self.request.user.is_authenticated:
				queryset = queryset.filter(
					models.Q(store__owner__role='STORE') | models.Q(store__owner=self.request.user)
				)
			else:
				queryset = queryset.filter(store__owner__role='STORE')
		return queryset


class PromotionImageViewSet(viewsets.ModelViewSet):
	queryset = PromotionImage.objects.select_related('promotion', 'promotion__store')
	serializer_class = PromotionImageSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_permissions(self):
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsStoreOwner()]
		return super().get_permissions()

# Create your views here.
