from django.conf import settings
from django.db import models


class Store(models.Model):
	STORE_TYPE_CHOICES = (('physical', 'Physical'), ('online', 'Online'))

	owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='stores')
	name = models.CharField(max_length=255)
	description = models.TextField(blank=True)
	address = models.CharField(max_length=255, blank=True)
	phone_number = models.CharField(max_length=20, blank=True)
	latitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
	longitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
	type = models.CharField(max_length=10, choices=STORE_TYPE_CHOICES, default='physical')
	profile_image = models.ImageField(upload_to='stores/profiles/', blank=True, null=True)
	cover_image = models.ImageField(upload_to='stores/covers/', blank=True, null=True)
	created_at = models.DateTimeField(auto_now_add=True)

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return self.name


class Follower(models.Model):
	user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='following')
	store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='followers')
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		unique_together = ('user', 'store')

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return f"{self.user} -> {self.store}"
