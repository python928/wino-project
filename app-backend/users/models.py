from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone
from datetime import timedelta


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
	allow_nearby_visibility = models.BooleanField(
		default=True,
		help_text='Whether this store can appear in nearby distance-based search.',
	)
	location_updated_at = models.DateTimeField(blank=True, null=True, help_text='Last time GPS coordinates were changed')
	store_type = models.CharField(max_length=10, choices=[('physical', 'Physical'), ('online', 'Online')], default='physical')
	cover_image = models.ImageField(upload_to='users/covers/', blank=True, null=True)

	# Social Accounts
	facebook = models.CharField(max_length=255, blank=True, default='')
	instagram = models.CharField(max_length=255, blank=True, default='')
	whatsapp = models.CharField(max_length=50, blank=True, default='')
	tiktok = models.CharField(max_length=255, blank=True, default='')
	youtube = models.CharField(max_length=255, blank=True, default='')

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


class PhoneOTP(models.Model):
	phone = models.CharField(max_length=20, db_index=True)
	code = models.CharField(max_length=6)
	created_at = models.DateTimeField(auto_now_add=True)
	expires_at = models.DateTimeField()
	attempts = models.PositiveSmallIntegerField(default=0)
	is_verified = models.BooleanField(default=False)

	class Meta:
		ordering = ['-created_at']

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return f"OTP({self.phone})"

	@property
	def is_expired(self) -> bool:
		return timezone.now() >= self.expires_at

	@classmethod
	def expiry_time(cls) -> timezone.datetime:
		return timezone.now() + timedelta(minutes=5)


class StoreReport(models.Model):
	REASON_SPAM = 'spam'
	REASON_FAKE = 'fake'
	REASON_FRAUD = 'fraud'
	REASON_OFFENSIVE = 'offensive'
	REASON_OTHER = 'other'

	REASON_CHOICES = (
		(REASON_SPAM, 'Spam'),
		(REASON_FAKE, 'Fake Store'),
		(REASON_FRAUD, 'Fraud / Scam'),
		(REASON_OFFENSIVE, 'Offensive Content'),
		(REASON_OTHER, 'Other'),
	)

	STATUS_PENDING = 'pending'
	STATUS_REVIEWED = 'reviewed'
	STATUS_REJECTED = 'rejected'
	STATUS_CHOICES = (
		(STATUS_PENDING, 'Pending'),
		(STATUS_REVIEWED, 'Reviewed'),
		(STATUS_REJECTED, 'Rejected'),
	)

	reporter = models.ForeignKey(
		'User',
		on_delete=models.CASCADE,
		related_name='store_reports_sent',
	)
	store = models.ForeignKey(
		'User',
		on_delete=models.CASCADE,
		related_name='store_reports_received',
	)
	reason = models.CharField(max_length=20, choices=REASON_CHOICES)
	details = models.TextField(blank=True, default='')
	status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']
		unique_together = ('reporter', 'store')

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return f"{self.reporter_id} -> {self.store_id} ({self.reason})"
