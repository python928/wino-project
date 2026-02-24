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


# Helper — add near the top of the State class or as a top-level function
def _resolve_store_name(store: dict) -> str:
    if store is None:
        return ''
    return store.get('display_name') or store.get('store_name') or store.get('username', '')
