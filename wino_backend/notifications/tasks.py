import logging
from celery import shared_task
from django.contrib.auth import get_user_model
from users.models import Follower

from .services import send_push_notification

logger = logging.getLogger(__name__)

User = get_user_model()

@shared_task
def async_send_new_post_notification(store_id, post_id, post_type, post_title):
    """
    Finds all followers of `store_id` and sends them a push notification
    that the store just posted a new item.
    """
    try:
        store = User.objects.get(id=store_id)
    except User.DoesNotExist:
        logger.error(f"Store {store_id} not found when trying to send notification.")
        return

    # Find all users who follow this store
    followers = Follower.objects.filter(followed_user=store).select_related('user')
    
    success_count = 0
    failure_count = 0

    notification_title = f"New {post_type.capitalize()} from {store.name or store.username}!"
    notification_body = f"Check out their new post: {post_title}"
    
    # Extra data to embed in the push payload so the app can route to it
    extra_data = {
        'post_id': str(post_id),
        'post_type': post_type, # e.g. 'product', 'promotion', 'pack'
        'store_id': str(store_id),
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    }

    # Decide the notification type for the DB record
    db_notif_type = 'system'
    if post_type == 'promotion':
        db_notif_type = 'new_promotion'
    elif post_type == 'product':
        db_notif_type = 'new_product'
    elif post_type == 'pack':
        db_notif_type = 'new_pack'

    # Collect follower user IDs to fan-out the push easily in one shot
    follower_ids = [f.user.id for f in followers]
    
    if not follower_ids:
        logger.info(f"Store {store_id} has no followers left. Skipped notification.")
        return {"success": 0, "failed": 0}

    try:
        send_push_notification(
            user_ids=follower_ids,
            title=notification_title,
            body=notification_body,
            sender_id=store_id,
            notification_type=db_notif_type,
            extra_data=extra_data,
        )
        logger.info(f"Successfully processed new post notification for {len(follower_ids)} followers.")
        return {"success": len(follower_ids), "failed": 0}
    except Exception as e:
        logger.error(f"Failed to fan-out push notifications: {e}")
        return {"success": 0, "failed": len(follower_ids)}
