from rest_framework import filters, permissions, viewsets
from django_filters.rest_framework import DjangoFilterBackend

from .models import Follower, Store
from .serializers import FollowerSerializer, StoreSerializer


class IsStoreOwnerOrAdmin(permissions.BasePermission):
	def has_object_permission(self, request, view, obj):
		return request.user.is_superuser or getattr(obj, 'owner', None) == request.user


class StoreViewSet(viewsets.ModelViewSet):
	queryset = Store.objects.select_related('owner').all()
	serializer_class = StoreSerializer
	filter_backends = [filters.SearchFilter, filters.OrderingFilter, DjangoFilterBackend]
	search_fields = ['name', 'description']
	ordering_fields = ['created_at', 'name']
	filterset_fields = ['owner']

	def get_permissions(self):
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsStoreOwnerOrAdmin()]
		return [permissions.IsAuthenticated()]

	def perform_create(self, serializer):
		serializer.save(owner=self.request.user)


class FollowerViewSet(viewsets.ModelViewSet):
	queryset = Follower.objects.select_related('user', 'store').all()
	serializer_class = FollowerSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_queryset(self):
		return self.queryset.filter(user=self.request.user)

	def perform_create(self, serializer):
		serializer.save(user=self.request.user)

# Create your views here.
