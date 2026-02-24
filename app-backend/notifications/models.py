from django.db import models
from django.conf import settings


class Notification(models.Model):
    """One row per notification event (fan-out via NotificationRecipient)."""

    TYPE_NEW_PRODUCT = 'new_product'
    TYPE_NEW_PACK = 'new_pack'
    TYPE_FLASH_SALE = 'flash_sale'
    TYPE_NEW_PROMOTION = 'new_promotion'
    TYPE_REVIEW = 'review'
    TYPE_SYSTEM = 'system'

    NOTIFICATION_TYPES = [
        (TYPE_NEW_PRODUCT, 'New Product'),
        (TYPE_NEW_PACK, 'New Pack'),
        (TYPE_FLASH_SALE, 'Flash Sale'),
        (TYPE_NEW_PROMOTION, 'New Promotion'),
        (TYPE_REVIEW, 'Review'),
        (TYPE_SYSTEM, 'System'),
    ]

    # The actor (store/user who triggered the notification)
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True, blank=True,
        on_delete=models.SET_NULL,
        related_name='sent_notifications',
    )
    notification_type = models.CharField(max_length=30, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=255)
    body = models.TextField()
    # Optional references
    product_id = models.IntegerField(null=True, blank=True)
    pack_id = models.IntegerField(null=True, blank=True)
    image_url = models.URLField(null=True, blank=True)
    extra_data = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.notification_type}] {self.title}"


class NotificationRecipient(models.Model):
    """Per-user delivery record — avoids 1000 rows for 1000 followers."""

    notification = models.ForeignKey(
        Notification,
        on_delete=models.CASCADE,
        related_name='recipients',
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notification_receipts',
    )
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('notification', 'user')
        ordering = ['-delivered_at']

    def __str__(self):
        return f"{self.user_id} <- {self.notification_id} (read={self.is_read})"
