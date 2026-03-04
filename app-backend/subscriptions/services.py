from datetime import timedelta

from django.utils import timezone
from rest_framework import serializers

from .models import (
	MerchantSubscription,
	SubscriptionPaymentRequest,
	SubscriptionPlan,
)

FREE_POST_LIMIT = 5


def get_active_subscription(user):
	now = timezone.now()
	active = (
		MerchantSubscription.objects.select_related('plan')
		.filter(
			store=user,
			status='active',
			start_date__lte=now,
			end_date__gte=now,
		)
		.order_by('-end_date')
		.first()
	)
	if active is not None:
		return active

	# Backfill behavior: if an approved payment exists but subscription record
	# was not created (legacy/admin flow), activate it automatically.
	approved_request = (
		SubscriptionPaymentRequest.objects.select_related('plan')
		.filter(
			merchant=user,
			status=SubscriptionPaymentRequest.STATUS_APPROVED,
		)
		.order_by('-created_at')
		.first()
	)
	if approved_request is not None:
		return activate_subscription_for_payment_request(approved_request)
	return None


def get_post_limit(user):
	active = get_active_subscription(user)
	if active is None:
		return FREE_POST_LIMIT
	return active.plan.max_products


def get_current_posts_count(user):
	from catalog.models import Pack, Product, Promotion

	return (
		Product.objects.filter(store=user).count()
		+ Promotion.objects.filter(store=user).count()
		+ Pack.objects.filter(merchant=user).count()
	)


def ensure_can_create_post(user):
	limit = get_post_limit(user)
	used = get_current_posts_count(user)
	if used < limit:
		return

	active_plans = list(
		SubscriptionPlan.objects.filter(is_active=True)
		.values('id', 'name', 'slug', 'price', 'duration_days', 'max_products')
	)
	raise serializers.ValidationError(
		{
			'code': 'subscription_required',
			'message': 'Free post limit reached. Please subscribe to continue publishing.',
			'free_limit': FREE_POST_LIMIT,
			'used_posts': used,
			'plans': active_plans,
		}
	)


def activate_subscription_for_payment_request(payment_request):
	"""
	Activate merchant subscription for an approved payment request.
	Returns created MerchantSubscription or None when request isn't approved.
	"""
	if payment_request.status != SubscriptionPaymentRequest.STATUS_APPROVED:
		return None

	now = timezone.now()
	# Keep a single active subscription window per merchant.
	MerchantSubscription.objects.filter(
		store=payment_request.merchant,
		status='active',
	).update(status='expired')

	return MerchantSubscription.objects.create(
		store=payment_request.merchant,
		plan=payment_request.plan,
		start_date=now,
		end_date=now + timedelta(days=payment_request.plan.duration_days),
		status='active',
	)
