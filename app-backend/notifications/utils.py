from django.contrib.auth import get_user_model
from fcm_django.models import FCMDevice

from .models import Notification, NotificationRecipient

User = get_user_model()


def create_and_send_notification(
    *,
    recipient_ids: list,
    notification_type: str,
    title: str,
    body: str,
    actor=None,
    product_id: int = None,
    pack_id: int = None,
    image_url: str = None,
    extra_data: dict = None,
):
    """
    Create ONE Notification and fan-out NotificationRecipient rows.
    Then push FCM to all recipient devices in one batch.

    recipient_ids: list of user PKs (e.g. all followers of a store)
    """
    notification = Notification.objects.create(
        actor=actor,
        notification_type=notification_type,
        title=title,
        body=body,
        product_id=product_id,
        pack_id=pack_id,
        image_url=image_url or '',
        extra_data=extra_data or {},
    )

    # Bulk-create recipient rows — O(1) notifications, O(followers) recipients
    NotificationRecipient.objects.bulk_create(
        [
            NotificationRecipient(notification=notification, user_id=uid)
            for uid in recipient_ids
        ],
        ignore_conflicts=True,
    )

    # Push FCM to all recipient devices in a single query
    devices = FCMDevice.objects.filter(
        user_id__in=recipient_ids, active=True
    )
    if devices.exists():
        devices.send_message(
            title=title,
            body=body,
            data={
                'notification_id': str(notification.pk),
                'type': notification_type,
                **(extra_data or {}),
            },
        )

    return notification


def push_notification(user_id: int, payload: dict):
    """Legacy single-user push (kept for backward compat)."""
    create_and_send_notification(
        recipient_ids=[user_id],
        notification_type=payload.get('type', 'system'),
        title=payload.get('title', 'Notification'),
        body=payload.get('content') or payload.get('message') or '',
        extra_data=payload,
    )
