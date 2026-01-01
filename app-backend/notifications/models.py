from django.conf import settings
from django.db import models


class Notification(models.Model):
	TYPE_CHOICES = (
		('promotion', 'Promotion'),
		('message', 'Message'),
		('system', 'System'),
		('sponsored', 'Sponsored'),
		('follow', 'Follow'),
	)

	sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sent_notifications')
	receiver = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='received_notifications')
	type = models.CharField(max_length=20, choices=TYPE_CHOICES)
	content = models.TextField()
	is_read = models.BooleanField(default=False)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']

# Create your models here.
