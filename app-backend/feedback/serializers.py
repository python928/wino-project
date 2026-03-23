from django.core.validators import FileExtensionValidator
from rest_framework import serializers

from .models import Feedback


class FeedbackSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.id')

    class Meta:
        model = Feedback
        fields = [
            'id',
            'user',
            'type',
            'message',
            'screenshot',
            'app_version',
            'platform',
            'device_info',
            'status',
            'admin_note',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'user', 'status', 'admin_note', 'created_at', 'updated_at']

    def validate_screenshot(self, value):
        if value is None:
            return value
        validator = FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png', 'webp'])
        validator(value)
        max_size = 5 * 1024 * 1024
        if getattr(value, 'size', 0) > max_size:
            raise serializers.ValidationError('Screenshot exceeds 5MB limit.')
        return value


class FeedbackAdminUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Feedback
        fields = ['status', 'admin_note']
