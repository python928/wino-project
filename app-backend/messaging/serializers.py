from rest_framework import serializers

from .models import Message
from users.serializers import UserSerializer


class MessageSerializer(serializers.ModelSerializer):
    sender_details = UserSerializer(source='sender', read_only=True)
    receiver_details = UserSerializer(source='receiver', read_only=True)
    sender = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Message
        fields = ['id', 'sender', 'receiver', 'sender_details', 'receiver_details',
                  'content', 'read_status', 'created_at']
        read_only_fields = ['id', 'sender', 'created_at']


class ConversationSerializer(serializers.Serializer):
    """Serializer for conversation list (grouped messages)"""
    user_id = serializers.IntegerField()
    username = serializers.CharField()
    name = serializers.CharField()
    profile_image = serializers.CharField(allow_null=True)
    last_message = serializers.CharField()
    last_message_time = serializers.DateTimeField()
    unread_count = serializers.IntegerField()
    is_sender = serializers.BooleanField()
