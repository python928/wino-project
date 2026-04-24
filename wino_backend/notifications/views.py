from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Notification, NotificationRecipient
from .serializers import NotificationSerializer
from .tasks import async_send_new_post_notification


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return (
            Notification.objects
            .filter(recipients__user=self.request.user)
            .select_related('actor')
            .prefetch_related('recipients')
            .order_by('-created_at')
        )

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    @action(detail=False, methods=['get'], url_path='unread-count')
    def unread_count(self, request):
        count = NotificationRecipient.objects.filter(
            user=request.user, is_read=False
        ).count()
        return Response({'unread_count': count})

    @action(detail=False, methods=['post'], url_path='mark-all-read')
    def mark_all_read(self, request):
        NotificationRecipient.objects.filter(
            user=request.user, is_read=False
        ).update(is_read=True, read_at=timezone.now())
        return Response({'status': 'ok'})

    @action(detail=True, methods=['post'], url_path='mark-read')
    def mark_read(self, request, pk=None):
        try:
            r = NotificationRecipient.objects.get(
                notification_id=pk, user=request.user
            )
            r.is_read = True
            r.read_at = timezone.now()
            r.save(update_fields=['is_read', 'read_at'])
            return Response({'status': 'ok'})
        except NotificationRecipient.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=False, methods=['post'], url_path='trigger')
    def trigger(self, request):
        """
        Trigger a new post notification for followers.
        Used when creating promotions, products, packs, etc.
        
        Request body:
        {
            "post_id": <int>,
            "post_type": "promotion" | "product" | "pack" | "ad",
            "post_title": "<str>"
        }
        """
        post_id = request.data.get('post_id')
        post_type = request.data.get('post_type', 'promotion')
        post_title = request.data.get('post_title', '')
        
        if not post_id:
            return Response(
                {'detail': 'post_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Queue notification task asynchronously
            async_send_new_post_notification(
                store_id=request.user.id,
                post_id=post_id,
                post_type=post_type,
                post_title=post_title,
            )
            return Response({
                'status': 'notification_queued',
                'post_id': post_id,
                'post_type': post_type,
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response(
                {'detail': f'Error triggering notification: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
