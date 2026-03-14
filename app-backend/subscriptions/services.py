from datetime import timedelta

from django.utils import timezone
from rest_framework import serializers

from .constants import DEFAULT_PLAN_FEATURES, DEFAULT_SUBSCRIPTION_PLANS
from .models import (
	MerchantSubscription,
	SubscriptionPaymentRequest,
	SubscriptionPlan,
)

FREE_POST_LIMIT = 5


def _to_int(value, default):
	try:
		return int(value)
	except Exception:
		return int(default)


def get_normalized_plan_features(plan):
	features = dict(DEFAULT_PLAN_FEATURES)
	if plan is None:
		return features
	custom = getattr(plan, 'plan_features', None) or {}
	for key, default_val in DEFAULT_PLAN_FEATURES.items():
		if key not in custom:
			continue
		if isinstance(default_val, bool):
			features[key] = bool(custom[key])
		else:
			features[key] = _to_int(custom[key], default_val)
	return features


def get_merchant_plan_features(user):
	active = get_active_subscription(user)
	plan = active.plan if active is not None else None
	return get_normalized_plan_features(plan)


def bootstrap_default_subscription_plans():
	for plan_data in DEFAULT_SUBSCRIPTION_PLANS:
		slug = str(plan_data.get('slug') or '').strip()
		if not slug:
			continue
		plan, _created = SubscriptionPlan.objects.get_or_create(
			slug=slug,
			defaults={
				'name': plan_data.get('name') or slug,
				'max_products': plan_data.get('max_products') or 10,
				'price': plan_data.get('price') or '0.00',
				'duration_days': plan_data.get('duration_days') or 30,
				'benefits': plan_data.get('benefits') or '',
				'is_active': bool(plan_data.get('is_active', True)),
				'plan_features': dict(plan_data.get('plan_features') or DEFAULT_PLAN_FEATURES),
			},
		)
		changed = False
		for field in ['name', 'max_products', 'price', 'duration_days', 'benefits', 'is_active']:
			value = plan_data.get(field)
			if value is not None and getattr(plan, field) != value:
				setattr(plan, field, value)
				changed = True
		features = dict(plan_data.get('plan_features') or DEFAULT_PLAN_FEATURES)
		if plan.plan_features != features:
			plan.plan_features = features
			changed = True
		if changed:
			plan.save()


def enforce_promotion_constraints(user, start_date, end_date, promotion_id=None, kind='promotion'):
	"""
	Enforce promotion capabilities from active subscription plan.
	Rules:
	- promotion feature enabled/disabled
	- max duration per promotion
	- max concurrent active promotions
	"""
	features = get_merchant_plan_features(user)
	is_ad = str(kind or '').lower() == 'advertising'
	prefix = 'ad_' if is_ad else 'promotion_'
	enabled_key = f'{prefix}enabled'
	max_duration_key = f'{prefix}max_duration_days'
	max_active_key = f'{prefix}max_active'
	max_impressions_key = f'{prefix}max_impressions'

	if not features.get(enabled_key, True):
		raise serializers.ValidationError(
			{
				'code': 'promotion_not_allowed_by_plan',
				'message': 'Your current plan does not include this type of promotional offer.',
				'plan_features': features,
			}
		)

	if start_date and end_date and end_date <= start_date:
		raise serializers.ValidationError({'end_date': 'End date must be after start date.'})

	if start_date and end_date:
		duration_days = max(1, int((end_date - start_date).total_seconds() // 86400) + 1)
		max_duration = _to_int(
			features.get(max_duration_key),
			DEFAULT_PLAN_FEATURES[max_duration_key],
		)
		if duration_days > max_duration:
			raise serializers.ValidationError(
				{
					'end_date': f'Promotion duration exceeds your plan limit ({max_duration} days).',
					'plan_features': features,
				}
			)

	# Late import to avoid circular dependency.
	from catalog.models import Promotion

	now = timezone.now()
	active_qs = Promotion.objects.filter(
		store=user,
		is_active=True,
		start_date__lte=now,
		end_date__gte=now,
	)
	if is_ad:
		active_qs = active_qs.filter(kind='advertising')
	else:
		active_qs = active_qs.exclude(kind='advertising')
	if promotion_id:
		active_qs = active_qs.exclude(id=promotion_id)

	max_active = _to_int(
		features.get(max_active_key),
		DEFAULT_PLAN_FEATURES[max_active_key],
	)
	if active_qs.count() >= max_active:
		raise serializers.ValidationError(
			{
				'code': 'promotion_active_limit_reached',
				'message': f'Your plan allows only {max_active} active promotions at the same time.',
				'plan_features': features,
			}
		)

	return features


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
		.values('id', 'name', 'slug', 'price', 'duration_days', 'max_products', 'plan_features')
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
