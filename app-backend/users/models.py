from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
	class Roles(models.TextChoices):
		USER = 'USER', 'User'
		STORE = 'STORE', 'Store Owner'
		ADMIN = 'ADMIN', 'Admin'

	name = models.CharField(max_length=255)
	phone = models.CharField(max_length=20, blank=True, null=True)
	role = models.CharField(max_length=10, choices=Roles.choices, default=Roles.USER)
	profile_image = models.ImageField(upload_to='users/profiles/', blank=True, null=True)

	# Remove inherited fields we don't need
	first_name = None
	last_name = None

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return self.name or self.username

	@property
	def is_store_owner(self) -> bool:
		return self.role == self.Roles.STORE

# Create your models here.
