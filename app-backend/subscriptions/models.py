from django.conf import settings
from django.db import models
from .constants import DEFAULT_SUBSCRIPTION_INSTRUCTIONS, DEFAULT_SUBSCRIPTION_RIB


def default_plan_features():
	from .constants import DEFAULT_PLAN_FEATURES
	return dict(DEFAULT_PLAN_FEATURES)


class SubscriptionPlan(models.Model):
	name = models.CharField(max_length=255)
	slug = models.SlugField(max_length=60, unique=True, default='')
	max_products = models.IntegerField()
	price = models.DecimalField(max_digits=10, decimal_places=2)
	duration_days = models.IntegerField()
	benefits = models.TextField(blank=True, default='')
	plan_features = models.JSONField(default=default_plan_features, blank=True)
	is_active = models.BooleanField(default=True)

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return self.name


class MerchantSubscription(models.Model):
	STATUS_CHOICES = (('active', 'Active'), ('expired', 'Expired'))

	# Unified: store == users.User
	store = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='subscriptions')
	plan = models.ForeignKey(SubscriptionPlan, on_delete=models.CASCADE)
	start_date = models.DateTimeField()
	end_date = models.DateTimeField()
	status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='active')

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return f"{self.store} - {self.plan}"


class SubscriptionPaymentRequest(models.Model):
	REASON_UNREADABLE_PROOF = 'unreadable_proof'
	REASON_AMOUNT_MISMATCH = 'amount_mismatch'
	REASON_MISSING_REFERENCE = 'missing_reference'
	REASON_OTHER = 'other'
	REASON_CHOICES = (
		(REASON_UNREADABLE_PROOF, 'Unreadable proof'),
		(REASON_AMOUNT_MISMATCH, 'Amount mismatch'),
		(REASON_MISSING_REFERENCE, 'Missing transfer reference'),
		(REASON_OTHER, 'Other'),
	)

	STATUS_PENDING = 'pending'
	STATUS_APPROVED = 'approved'
	STATUS_REJECTED = 'rejected'
	STATUS_CHOICES = (
		(STATUS_PENDING, 'Pending'),
		(STATUS_APPROVED, 'Approved'),
		(STATUS_REJECTED, 'Rejected'),
	)

	merchant = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		on_delete=models.CASCADE,
		related_name='subscription_payment_requests',
	)
	plan = models.ForeignKey(
		SubscriptionPlan,
		on_delete=models.CASCADE,
		related_name='payment_requests',
	)
	status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
	payment_note = models.TextField(blank=True, default='')
	status_reason_code = models.CharField(max_length=40, choices=REASON_CHOICES, blank=True, default='')
	status_reason_text = models.TextField(blank=True, default='')
	reviewed_by = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		on_delete=models.SET_NULL,
		null=True,
		blank=True,
		related_name='reviewed_subscription_payment_requests',
	)
	reviewed_at = models.DateTimeField(null=True, blank=True)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return f"{self.merchant_id} -> {self.plan_id} ({self.status})"


class SubscriptionPaymentProof(models.Model):
	payment_request = models.ForeignKey(
		SubscriptionPaymentRequest,
		on_delete=models.CASCADE,
		related_name='proofs',
	)
	image = models.ImageField(upload_to='subscriptions/payment_proofs/')
	created_at = models.DateTimeField(auto_now_add=True)

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return f"Proof {self.id} for request {self.payment_request_id}"


class SubscriptionPaymentConfig(models.Model):
	rib = models.CharField(max_length=64, default=DEFAULT_SUBSCRIPTION_RIB)
	instructions = models.TextField(
		default=DEFAULT_SUBSCRIPTION_INSTRUCTIONS
	)
	is_active = models.BooleanField(default=True)
	updated_at = models.DateTimeField(auto_now=True)

	class Meta:
		verbose_name = 'Subscription Payment Config'
		verbose_name_plural = 'Subscription Payment Config'

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return f"Payment Config ({'active' if self.is_active else 'inactive'})"

# Create your models here.
