from fcm_django.models import FCMDevice
from rest_framework import permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Notification
from .serializers import DeviceSerializer, NotificationSerializer


class NotificationViewSet(viewsets.ModelViewSet):
	serializer_class = NotificationSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_queryset(self):
		return Notification.objects.filter(receiver=self.request.user)

	def perform_create(self, serializer):
		serializer.save(sender=self.request.user)

	@action(detail=True, methods=['post'])
	def mark_read(self, request, pk=None):
		notification = self.get_object()
		notification.is_read = True
		notification.save(update_fields=['is_read'])
		return Response({'status': 'read'})


class DeviceViewSet(viewsets.ModelViewSet):
	serializer_class = DeviceSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_queryset(self):
		return FCMDevice.objects.filter(user=self.request.user)

	def perform_create(self, serializer):
		serializer.save(user=self.request.user, active=True)

# Create your views here.
