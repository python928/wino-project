from fcm_django.models import FCMDevice


def push_notification(user_id: int, payload: dict):
    """Send notification payload to user devices via FCM."""
    devices = FCMDevice.objects.filter(user_id=user_id, active=True)
    if not devices.exists():
        return

    title = payload.get('title') or payload.get('type', 'Notification')
    body = payload.get('content') or payload.get('message') or payload.get('type', '')
    data = payload.copy()

    devices.send_message(title=title, body=body, data=data)
