from django.db.models.signals import post_save
from django.dispatch import receiver

from notifications.models import Notification
from notifications.utils import push_notification

from .models import Message


@receiver(post_save, sender=Message)
def handle_new_message(sender, instance: Message, created: bool, **kwargs):
    if not created:
        return

    # Persist a notification entry
    Notification.objects.create(
        sender=instance.sender,
        receiver=instance.receiver,
        type='message',
        content=instance.content,
    )

    # Push notification stream via FCM
    push_notification(
        instance.receiver_id,
        {
            'type': 'message',
            'message_id': instance.id,
            'content': instance.content,
        },
    )
