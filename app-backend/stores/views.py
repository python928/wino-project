from django.db import models
from rest_framework import filters, permissions, viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
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

	def get_queryset(self):
		queryset = super().get_queryset()
		# For list/retrieve actions, only show stores where owner role is STORE
		if self.action in ['list', 'retrieve']:
			if self.request.user.is_authenticated:
				# Allow owners to see their own store regardless of role
				queryset = queryset.filter(
					models.Q(owner__role='STORE') | models.Q(owner=self.request.user)
				)
			else:
				queryset = queryset.filter(owner__role='STORE')
		return queryset

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

	@action(detail=False, methods=['post'], url_path='toggle')
	def toggle(self, request):
		"""Toggle follow status for a store."""
		store_id = request.data.get('store')
		if not store_id:
			return Response({'error': 'store is required'}, status=status.HTTP_400_BAD_REQUEST)

		try:
			store = Store.objects.get(id=store_id)
		except Store.DoesNotExist:
			return Response({'error': 'Store not found'}, status=status.HTTP_404_NOT_FOUND)

		follower, created = Follower.objects.get_or_create(user=request.user, store=store)
		if not created:
			# Already following, so unfollow
			follower.delete()
			return Response({'status': 'unfollowed', 'is_following': False}, status=status.HTTP_200_OK)

		return Response({'status': 'followed', 'is_following': True}, status=status.HTTP_201_CREATED)

	@action(detail=False, methods=['get'], url_path='check/(?P<store_id>[^/.]+)')
	def check(self, request, store_id=None):
		"""Check if user is following a store."""
		is_following = Follower.objects.filter(user=request.user, store_id=store_id).exists()
		return Response({'is_following': is_following})

# Create your views here.
