from django.db.models.signals import post_save
from django.dispatch import receiver

from notifications.models import Notification
from notifications.utils import push_notification

from .models import Follower


@receiver(post_save, sender=Follower)
def handle_new_follower(sender, instance: Follower, created: bool, **kwargs):
    if not created:
        return
    Notification.objects.create(
        sender=instance.user,
        receiver=instance.store.owner,
        type='follow',
        content=f'{instance.user.username} followed your store {instance.store.name}',
    )
    push_notification(
        instance.store.owner_id,
        {
            'type': 'follow',
            'user_id': instance.user_id,
            'store_id': instance.store_id,
            'content': f'{instance.user.username} followed your store {instance.store.name}',
        },
    )
