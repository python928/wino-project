from fcm_django.models import FCMDevice
from rest_framework import serializers

from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    sender = serializers.ReadOnlyField(source='sender.id')

    class Meta:
        model = Notification
        fields = ['id', 'sender', 'receiver', 'type', 'content', 'is_read', 'created_at']
        read_only_fields = ['id', 'sender', 'created_at']


class DeviceSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.id')

    class Meta:
        model = FCMDevice
        fields = ['id', 'name', 'registration_id', 'type', 'user', 'active']
        read_only_fields = ['id', 'user']
