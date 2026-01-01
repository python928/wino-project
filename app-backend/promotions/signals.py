from django.db.models.signals import post_save
from django.dispatch import receiver

from notifications.models import Notification
from notifications.utils import push_notification
from stores.models import Follower

from .models import Promotion


@receiver(post_save, sender=Promotion)
def notify_promotion(sender, instance: Promotion, created: bool, **kwargs):
    if not created:
        return
    followers = Follower.objects.filter(store=instance.store).select_related('user')
    for follower in followers:
        Notification.objects.create(
            sender=instance.store.owner,
            receiver=follower.user,
            type='promotion',
            content=f'New promotion: {instance.name}',
        )
        push_notification(
            follower.user_id,
            {
                'type': 'promotion',
                'promotion_id': instance.id,
                'store_id': instance.store_id,
                'name': instance.name,
                'content': f'New promotion: {instance.name}',
            },
        )
