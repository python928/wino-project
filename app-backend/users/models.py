from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
	# User basic info
	# Keep model-level default to make migrations/backfills possible.
	# API-level validation still requires a real name (see RegisterSerializer).
	name = models.CharField(max_length=255, blank=True, default='')
	phone = models.CharField(max_length=20, blank=True, null=True)
	GENDER_CHOICES = [
		('male', 'Male'),
		('female', 'Female'),
	]
	gender = models.CharField(max_length=10, choices=GENDER_CHOICES, blank=True, default='')
	birthday = models.DateField(blank=True, null=True)
	profile_image = models.ImageField(upload_to='users/profiles/', blank=True, null=True)
	
	# Store info (merged from Store model)
	store_description = models.TextField(blank=True)
	address = models.CharField(max_length=255, blank=True)
	latitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
	longitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
	store_type = models.CharField(max_length=10, choices=[('physical', 'Physical'), ('online', 'Online')], default='physical')
	cover_image = models.ImageField(upload_to='users/covers/', blank=True, null=True)

	# Remove inherited fields we don't need
	first_name = None
	last_name = None

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return self.name or self.username

	@property
	def is_store_owner(self) -> bool:
		return True  # All users are store owners now

# Create your models here.


class Follower(models.Model):
	user = models.ForeignKey('User', on_delete=models.CASCADE, related_name='following')
	followed_user = models.ForeignKey('User', on_delete=models.CASCADE, related_name='followers')
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		unique_together = ('user', 'followed_user')

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return f"{self.user} follows {self.followed_user}"
