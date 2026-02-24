import logging
import firebase_admin
from firebase_admin import messaging
from fcm_django.models import FCMDevice
from .models import Notification, NotificationRecipient

logger = logging.getLogger(__name__)

def send_push_notification(user_ids, title, body, sender_id=None, notification_type='system', extra_data=None):
    """
    Creates a Notification record and attempts to send a FCM push to all devices registered for that user.
    """
    if not isinstance(user_ids, list):
        user_ids = [user_ids]
        
    # Extract post references if they exist
    post_id = extra_data.get('post_id') if extra_data else None
    post_type = extra_data.get('post_type') if extra_data else None

    # Determine numeric IDs based on post_type
    product_id = int(post_id) if post_id and post_type == 'product' else None
    pack_id = int(post_id) if post_id and post_type == 'pack' else None

    # 1. Create the persistent notification record in DB (except if sender == receiver)
    notification = None
    if sender_id:
        notification = Notification.objects.create(
            actor_id=sender_id,
            notification_type=notification_type,
            title=title,
            body=body,
            product_id=product_id,
            pack_id=pack_id,
            extra_data=extra_data or {},
        )
        # Create recipients via bulk_create
        recipients = []
        for uid in user_ids:
            if uid != sender_id:
                recipients.append(NotificationRecipient(notification=notification, user_id=uid))
        if recipients:
            NotificationRecipient.objects.bulk_create(recipients, ignore_conflicts=True)

    # 2. Prevent crashing if FCM json missing (the user explicitly mentioned "not added to server")
    if not firebase_admin._apps:
        logger.warning("Firebase Admin not initialized, skipping push send but notification saved and will be fetched!")
        return False

    # 3. Get the FCM Devices configured for the user
    devices = FCMDevice.objects.filter(user_id__in=user_ids, active=True)
    if not devices.exists():
        return False

    # 4. Create the messaging message payload
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data=extra_data or {},
    )

    # 5. Send asynchronously via fcm-django
    try:
        response = devices.send_message(message)
        return response
    except Exception as e:
        logger.error(f"FCM push failed: {e}")
        return False
