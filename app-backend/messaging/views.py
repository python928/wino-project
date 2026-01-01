from django.db.models import Q, Count, Max, Case, When, BooleanField
from rest_framework import permissions, viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Message
from .serializers import MessageSerializer, ConversationSerializer


class MessageViewSet(viewsets.ModelViewSet):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        queryset = (Message.objects.filter(sender=user) | Message.objects.filter(receiver=user)).distinct()

        # Filter by conversation partner
        other_user_id = self.request.query_params.get('user_id')
        if other_user_id:
            queryset = queryset.filter(
                Q(sender_id=other_user_id) | Q(receiver_id=other_user_id)
            )

        return queryset.select_related('sender', 'receiver').order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(sender=self.request.user)

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        message = self.get_object()
        # Only receiver can mark as read
        if message.receiver == request.user:
            message.read_status = True
            message.save(update_fields=['read_status'])
        return Response({'status': 'read'})

    @action(detail=False, methods=['post'])
    def mark_conversation_read(self, request):
        """Mark all messages from a user as read"""
        other_user_id = request.data.get('user_id')
        if not other_user_id:
            return Response({'error': 'user_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        updated = Message.objects.filter(
            sender_id=other_user_id,
            receiver=request.user,
            read_status=False
        ).update(read_status=True)

        return Response({'status': 'read', 'updated_count': updated})

    @action(detail=False, methods=['get'])
    def conversations(self, request):
        """Get list of conversations grouped by other user"""
        user = request.user

        # Get all messages involving current user
        messages = Message.objects.filter(
            Q(sender=user) | Q(receiver=user)
        ).select_related('sender', 'receiver').order_by('-created_at')

        # Group by conversation partner
        conversations = {}
        for message in messages:
            other = message.receiver if message.sender == user else message.sender

            if other.id not in conversations:
                # Count unread messages from this user
                unread_count = Message.objects.filter(
                    sender=other,
                    receiver=user,
                    read_status=False
                ).count()

                conversations[other.id] = {
                    'user_id': other.id,
                    'username': other.username,
                    'first_name': other.first_name or '',
                    'last_name': other.last_name or '',
                    'profile_image': other.profile_image.url if other.profile_image else None,
                    'last_message': message.content,
                    'last_message_time': message.created_at,
                    'unread_count': unread_count,
                    'is_sender': message.sender == user,
                }

        # Sort by last message time
        result = sorted(
            conversations.values(),
            key=lambda x: x['last_message_time'],
            reverse=True
        )

        serializer = ConversationSerializer(result, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Get total unread message count"""
        count = Message.objects.filter(
            receiver=request.user,
            read_status=False
        ).count()
        return Response({'unread_count': count})
