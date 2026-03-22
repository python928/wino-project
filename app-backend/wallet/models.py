from django.conf import settings
from django.db import models


class CoinTransaction(models.Model):
	user = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		on_delete=models.CASCADE,
		related_name='coin_transactions',
	)
	amount_signed = models.IntegerField(help_text='Signed change in coin balance.')
	reason = models.CharField(max_length=120, default='', blank=True)
	related_model = models.CharField(max_length=120, default='', blank=True)
	related_id = models.PositiveIntegerField(null=True, blank=True)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']


class CoinPackPlan(models.Model):
	pack_id = models.SlugField(max_length=80, unique=True)
	coins_amount = models.PositiveIntegerField(default=0)
	price_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
	original_price_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
	title = models.CharField(max_length=120, blank=True, default='')
	promo_badge = models.CharField(max_length=60, blank=True, default='')
	is_promoted = models.BooleanField(default=False)
	sort_order = models.PositiveIntegerField(default=0)
	is_active = models.BooleanField(default=True)
	created_at = models.DateTimeField(auto_now_add=True)
	updated_at = models.DateTimeField(auto_now=True)

	class Meta:
		ordering = ['sort_order', 'coins_amount', 'id']

	def __str__(self):
		label = self.title or self.pack_id
		return label


class CoinPurchase(models.Model):
	STATUS_PENDING = 'pending'
	STATUS_COMPLETED = 'completed'
	STATUS_FAILED = 'failed'
	STATUS_CHOICES = (
		(STATUS_PENDING, 'Pending'),
		(STATUS_COMPLETED, 'Completed'),
		(STATUS_FAILED, 'Failed'),
	)

	user = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		on_delete=models.CASCADE,
		related_name='coin_purchases',
	)
	pack_id = models.CharField(max_length=80, default='', blank=True)
	coins_amount = models.PositiveIntegerField(default=0)
	price_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
	payment_note = models.TextField(blank=True, default='')
	status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
	approved_at = models.DateTimeField(null=True, blank=True)
	approved_by = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		on_delete=models.SET_NULL,
		null=True,
		blank=True,
		related_name='approved_coin_purchases',
	)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']


class CoinPurchaseProof(models.Model):
	purchase = models.ForeignKey(
		CoinPurchase,
		on_delete=models.CASCADE,
		related_name='proofs',
	)
	image = models.ImageField(upload_to='wallet/purchase_proofs/')
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['created_at']
