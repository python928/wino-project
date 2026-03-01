from django.utils import timezone
from rest_framework import serializers

from .models import MerchantSubscription, SubscriptionPlan

FREE_POST_LIMIT = 5


def get_active_subscription(user):
	now = timezone.now()
	return (
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
