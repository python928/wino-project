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
	store_type = models.CharField(
		max_length=10,
		choices=[('', 'Not specified'), ('physical', 'Physical'), ('online', 'Online')],
		blank=True,
		default='',
	)
	cover_image = models.ImageField(upload_to='users/covers/', blank=True, null=True)

	# Social Accounts
	facebook = models.CharField(max_length=255, blank=True, default='')
	instagram = models.CharField(max_length=255, blank=True, default='')
	whatsapp = models.CharField(max_length=50, blank=True, default='')
	tiktok = models.CharField(max_length=255, blank=True, default='')
	youtube = models.CharField(max_length=255, blank=True, default='')
	show_phone_public = models.BooleanField(default=True)
	show_social_public = models.BooleanField(default=True)

	# Monetization balances
	coins_balance = models.PositiveIntegerField(default=0)
	post_coins = models.PositiveIntegerField(default=0)
	ad_view_coins = models.PositiveIntegerField(default=0)
	last_daily_coin_grant = models.DateTimeField(null=True, blank=True)
	verification_status = models.CharField(
		max_length=20,
		choices=[
			('none', 'None'),
			('eligible', 'Eligible'),
			('pending', 'Pending'),
			('verified', 'Verified'),
			('rejected', 'Rejected'),
		],
		default='none',
	)
	is_verified = models.BooleanField(default=False)
	verified_at = models.DateTimeField(null=True, blank=True)
	verified_by = models.ForeignKey(
		'self',
		on_delete=models.SET_NULL,
		null=True,
		blank=True,
		related_name='verified_stores',
	)
	verification_note = models.TextField(blank=True, default='')

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
	LEVEL_LOW = 'low'
	LEVEL_MEDIUM = 'medium'
	LEVEL_HIGH = 'high'
	LEVEL_CHOICES = (
		(LEVEL_LOW, 'Low'),
		(LEVEL_MEDIUM, 'Medium'),
		(LEVEL_HIGH, 'High'),
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
	seriousness_score = models.PositiveSmallIntegerField(default=0)
	seriousness_level = models.CharField(max_length=10, choices=LEVEL_CHOICES, default=LEVEL_LOW)
	evidence_snapshot = models.JSONField(default=dict, blank=True)
	is_low_credibility = models.BooleanField(default=True)
	scored_at = models.DateTimeField(null=True, blank=True)
	reporter_reputation_score_at_submission = models.PositiveSmallIntegerField(null=True, blank=True)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']
		unique_together = ('reporter', 'store')

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return f"{self.reporter_id} -> {self.store_id} ({self.reason})"

class SystemSettings(models.Model):
	first_login_coins = models.PositiveIntegerField(
		default=10,
		help_text='Amount of coins granted to new users upon registration.',
	)
	daily_login_coins = models.PositiveIntegerField(
		default=3,
		help_text='The target balance for daily login. If a user has less than this, they get topped up to this amount.',
	)

	class Meta:
		verbose_name = 'System Settings'
		verbose_name_plural = 'System Settings'

	def save(self, *args, **kwargs):
		self.pk = 1
		super().save(*args, **kwargs)

	@classmethod
	def get_settings(cls):
		obj, _ = cls.objects.get_or_create(pk=1)
		return obj


class TrustSettings(models.Model):
	"""Singleton settings for trust/reputation scoring and moderation tuning."""

	report_quick_submit_seconds = models.PositiveIntegerField(default=20)
	review_quick_submit_seconds = models.PositiveIntegerField(default=25)
	minimum_interactions_for_high_credibility = models.PositiveIntegerField(default=3)
	reporter_reputation_default = models.PositiveSmallIntegerField(default=50)
	reporter_reputation_low_quality_penalty = models.PositiveSmallIntegerField(default=8)
	reporter_reputation_good_report_bonus = models.PositiveSmallIntegerField(default=3)
	report_weight_interactions = models.PositiveSmallIntegerField(default=40)
	report_weight_recency = models.PositiveSmallIntegerField(default=20)
	report_weight_reputation = models.PositiveSmallIntegerField(default=20)
	report_weight_account_age = models.PositiveSmallIntegerField(default=20)
	review_weight_dwell = models.PositiveSmallIntegerField(default=35)
	review_weight_interactions = models.PositiveSmallIntegerField(default=35)
	review_weight_account_age = models.PositiveSmallIntegerField(default=15)
	review_weight_history = models.PositiveSmallIntegerField(default=15)
	verified_min_credible_positive_reviews = models.PositiveIntegerField(default=10)
	verified_max_credible_negative_ratio_percent = models.PositiveSmallIntegerField(default=20)
	verified_min_account_age_days = models.PositiveIntegerField(default=30)
	auto_verify_eligible_stores = models.BooleanField(default=False)
	report_cooldown_minutes = models.PositiveIntegerField(default=10)
	review_cooldown_minutes = models.PositiveIntegerField(default=5)
	max_reports_per_day = models.PositiveIntegerField(default=20)
	analytics_retention_days = models.PositiveIntegerField(default=180)

	class Meta:
		verbose_name = 'Trust Settings'
		verbose_name_plural = 'Trust Settings'

	def save(self, *args, **kwargs):
		self.pk = 1
		super().save(*args, **kwargs)

	@classmethod
	def get_settings(cls):
		obj, _ = cls.objects.get_or_create(pk=1)
		return obj


class AbuseFlag(models.Model):
	SIGNAL_REPORT_SPAM = 'report_spam'
	SIGNAL_LOW_CRED_REPORT = 'low_cred_report'
	SIGNAL_REVIEW_SPAM = 'review_spam'
	SIGNAL_CHOICES = (
		(SIGNAL_REPORT_SPAM, 'Report Spam'),
		(SIGNAL_LOW_CRED_REPORT, 'Low Credibility Report'),
		(SIGNAL_REVIEW_SPAM, 'Review Spam'),
	)

	TARGET_STORE = 'store'
	TARGET_PRODUCT = 'product'
	TARGET_ACCOUNT = 'account'
	TARGET_CHOICES = (
		(TARGET_STORE, 'Store'),
		(TARGET_PRODUCT, 'Product'),
		(TARGET_ACCOUNT, 'Account'),
	)

	actor = models.ForeignKey('User', on_delete=models.CASCADE, related_name='abuse_flags')
	signal_type = models.CharField(max_length=40, choices=SIGNAL_CHOICES)
	target_type = models.CharField(max_length=20, choices=TARGET_CHOICES)
	target_id = models.PositiveIntegerField(null=True, blank=True)
	count = models.PositiveIntegerField(default=1)
	metadata = models.JSONField(default=dict, blank=True)
	first_seen_at = models.DateTimeField(auto_now_add=True)
	last_seen_at = models.DateTimeField(auto_now=True)

	class Meta:
		ordering = ['-last_seen_at']
		indexes = [
			models.Index(fields=['actor', 'signal_type', 'target_type', 'target_id']),
		]
