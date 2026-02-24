from fcm_django.models import FCMDevice
from rest_framework import serializers
from .models import Notification, NotificationRecipient
from django.contrib.auth import get_user_model

User = get_user_model()


class SenderSerializer(serializers.ModelSerializer):
    """Minimal sender info including store avatar."""
    avatar = serializers.SerializerMethodField()
    store_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'store_name', 'avatar']

    def get_avatar(self, obj):
        request = self.context.get('request')
        if obj.profile_picture:
            url = obj.profile_picture.url
            if request:
                return request.build_absolute_uri(url)
            return url
        return None

    def get_store_name(self, obj):
        # Use name field if available, fallback to username
        return getattr(obj, 'name', None) or obj.username


class NotificationSerializer(serializers.ModelSerializer):
    actor_name = serializers.SerializerMethodField()
    actor_avatar = serializers.SerializerMethodField()
    is_read = serializers.SerializerMethodField()
    time_ago = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = [
            'id', 'notification_type', 'title', 'body',
            'actor_name', 'actor_avatar',
            'product_id', 'pack_id', 'image_url', 'extra_data',
            'is_read', 'time_ago', 'created_at',
        ]

    def _get_recipient(self, obj):
        request = self.context.get('request')
        if not request:
            return None
        # Cache per-object to avoid repeated DB hits
        cache_key = f'_recipient_{obj.pk}'
        if not hasattr(self, cache_key):
            try:
                setattr(self, cache_key,
                        obj.recipients.get(user=request.user))
            except NotificationRecipient.DoesNotExist:
                setattr(self, cache_key, None)
        return getattr(self, cache_key)

    def get_actor_name(self, obj):
        if obj.actor:
            return obj.actor.name or obj.actor.username
        return None

    def get_actor_avatar(self, obj):
        request = self.context.get('request')
        if obj.actor and obj.actor.profile_image:
            if request:
                return request.build_absolute_uri(obj.actor.profile_image.url)
            return obj.actor.profile_image.url
        return None

    def get_is_read(self, obj):
        r = self._get_recipient(obj)
        return r.is_read if r else False

    def get_time_ago(self, obj):
        from django.utils import timezone
        from datetime import timedelta
        now = timezone.now()
        diff = now - obj.created_at
        if diff < timedelta(minutes=1):
            return 'Just now'
        if diff < timedelta(hours=1):
            m = int(diff.total_seconds() // 60)
            return f'{m} min ago'
        if diff < timedelta(days=1):
            h = int(diff.total_seconds() // 3600)
            return f'{h} hour{"s" if h > 1 else ""} ago'
        if diff < timedelta(days=2):
            return 'Yesterday'
        d = diff.days
        return f'{d} days ago'


class DeviceSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.id')

    class Meta:
        model = FCMDevice
        fields = ['id', 'name', 'registration_id', 'type', 'user', 'active']
        read_only_fields = ['id', 'user']
