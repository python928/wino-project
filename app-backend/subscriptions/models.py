from django.conf import settings
from django.db import models


class SubscriptionPlan(models.Model):
	name = models.CharField(max_length=255)
	max_products = models.IntegerField()
	price = models.DecimalField(max_digits=10, decimal_places=2)
	duration_days = models.IntegerField()

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

# Create your models here.
