from django.conf import settings
from django.db import models


class Feedback(models.Model):
    TYPE_PROBLEM = 'problem'
    TYPE_SUGGESTION = 'suggestion'
    TYPE_CHOICES = (
        (TYPE_PROBLEM, 'Problem'),
        (TYPE_SUGGESTION, 'Suggestion'),
    )

    STATUS_OPEN = 'open'
    STATUS_IN_REVIEW = 'in_review'
    STATUS_RESOLVED = 'resolved'
    STATUS_REJECTED = 'rejected'
    STATUS_CHOICES = (
        (STATUS_OPEN, 'Open'),
        (STATUS_IN_REVIEW, 'In Review'),
        (STATUS_RESOLVED, 'Resolved'),
        (STATUS_REJECTED, 'Rejected'),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='feedback_items')
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    message = models.TextField()
    screenshot = models.ImageField(upload_to='feedback/screenshots/', null=True, blank=True)
    app_version = models.CharField(max_length=60, blank=True, default='')
    platform = models.CharField(max_length=40, blank=True, default='')
    device_info = models.CharField(max_length=255, blank=True, default='')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_OPEN)
    admin_note = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'Feedback#{self.id} by {self.user_id} ({self.type}/{self.status})'
