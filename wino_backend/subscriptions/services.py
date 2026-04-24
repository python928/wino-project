from datetime import datetime, timedelta
from collections import defaultdict

from django.utils import timezone
from django.db import transaction
from django.db.models import Count, F, Q, Sum
from rest_framework import serializers

from .constants import (
	DEFAULT_PLAN_FEATURES,
	DEFAULT_SUBSCRIPTION_PLANS,
)
from wallet import services as wallet_services
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
	Enforce logical promotion constraints.
	Rules:
	- end date after start date
	- max duration per promotion
	- max concurrent active promotions
	"""
	is_ad = str(kind or '').lower() == 'advertising'
	prefix = 'ad_' if is_ad else 'promotion_'
	max_duration_key = f'{prefix}max_duration_days'
	max_active_key = f'{prefix}max_active'
	max_impressions_key = f'{prefix}max_impressions'
	plan_features = get_merchant_plan_features(user)
	max_duration = _to_int(
		plan_features.get(max_duration_key),
		DEFAULT_PLAN_FEATURES[max_duration_key],
	)
	max_impressions = _to_int(
		plan_features.get(max_impressions_key),
		DEFAULT_PLAN_FEATURES[max_impressions_key],
	)

	if start_date and end_date and end_date <= start_date:
		raise serializers.ValidationError({'end_date': 'End date must be after start date.'})

	if start_date and end_date:
		# Calculate duration as (end - start), rounding to days
		# Allow small clock skew (+1 second tolerance) for client/server time differences
		duration_seconds = (end_date - start_date).total_seconds()
		duration_days = max(1, int(duration_seconds / 86400) + 1)
		# Add 1-day buffer for clock skew (server/app time differences)
		max_duration_with_buffer = max_duration + 1
		if duration_days > max_duration_with_buffer:
			raise serializers.ValidationError(
				{
					'end_date': f'Promotion duration exceeds the current limit ({max_duration} days).',
				}
			)

	now = timezone.now()
	if is_ad:
		# Ads are tracked in the dedicated ads app.
		from ads.models import AdCampaign

		active_qs = AdCampaign.objects.filter(
			store=user,
			is_active=True,
		).filter(
			Q(start_date__isnull=True) | Q(start_date__lte=now)
		).filter(
			Q(end_date__isnull=True) | Q(end_date__gte=now)
		)
		if promotion_id:
			active_qs = active_qs.exclude(id=promotion_id)
	else:
		# Late import to avoid circular dependency.
		from catalog.models import Promotion

		active_qs = Promotion.objects.filter(
			store=user,
			is_active=True,
		).filter(
			Q(start_date__isnull=True) | Q(start_date__lte=now)
		).filter(
			Q(end_date__isnull=True) | Q(end_date__gte=now)
		)
		if promotion_id:
			active_qs = active_qs.exclude(id=promotion_id)

	max_active = _to_int(
		plan_features.get(max_active_key),
		DEFAULT_PLAN_FEATURES[max_active_key],
	)
	if active_qs.count() >= max_active:
		raise serializers.ValidationError(
			{
				'code': 'promotion_active_limit_reached',
				'message': f'You can only have {max_active} active promotions at the same time.',
			}
		)

	return {
		'max_duration_days': max_duration,
		'max_active': max_active,
		max_impressions_key: max_impressions,
	}


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


def get_coin_configuration():
	costs = wallet_services.get_coin_costs()
	return {
		'product_post_cost': int(costs['product']),
		'pack_post_cost': int(costs['pack']),
		'promotion_post_cost': int(costs['promotion']),
		'ad_view_cost': int(costs['ad_view']),
	}


def get_coin_wallet_snapshot(user):
	cfg = get_coin_configuration()
	return {
		'coins_balance': int(getattr(user, 'coins_balance', 0) or 0),
		'post_coins': int(getattr(user, 'coins_balance', 0) or 0),
		'ad_view_coins': int(getattr(user, 'coins_balance', 0) or 0),
		'costs': cfg,
	}


def _consume_user_coins(user, *, field_name, amount, error_code, action_label):
	amount = int(amount or 0)
	if amount <= 0:
		return

	with transaction.atomic():
		updated = type(user).objects.filter(
			id=user.id,
			**{f'{field_name}__gte': amount},
		).update(**{field_name: F(field_name) - amount})
		if not updated:
			fresh = type(user).objects.only(field_name).get(id=user.id)
			available = int(getattr(fresh, field_name, 0) or 0)
			raise serializers.ValidationError(
				{
					'code': error_code,
					'message': f'Insufficient balance for {action_label}.',
					'required': amount,
					'available': available,
					'field': field_name,
				}
			)

	user.refresh_from_db(fields=[field_name])


def consume_post_coins_for_publish(user):
	return wallet_services.ensure_can_create_post(user, 'product')


def consume_ad_view_coins(user, impressions):
	impressions = int(impressions or 0)
	if impressions <= 0:
		raise serializers.ValidationError(
			{'max_impressions': 'Ad impressions must be greater than zero.'}
		)
	costs = wallet_services.get_coin_costs()
	required = impressions * int(costs['ad_view'])
	wallet_services.consume_coins(
		user,
		amount=required,
		reason='ad_impression_reserve',
	)
	return required


def get_current_posts_count(user):
	from catalog.models import Pack, Product, Promotion

	return (
		Product.objects.filter(store=user).count()
		+ Promotion.objects.filter(store=user).count()
		+ Pack.objects.filter(merchant=user).count()
	)


def ensure_can_create_post(user, post_type='product'):
	# New monetization model: post publishing consumes Post Coins.
	wallet_services.ensure_can_create_post(user, post_type)


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


def approve_payment_request(payment_request, *, reviewer, reason_code='', reason_text=''):
	"""Approve request idempotently and activate subscription exactly once."""
	with transaction.atomic():
		locked = SubscriptionPaymentRequest.objects.select_for_update().select_related('plan', 'merchant').get(id=payment_request.id)
		if locked.status == SubscriptionPaymentRequest.STATUS_APPROVED:
			return locked, False, get_active_subscription(locked.merchant)
		if locked.status == SubscriptionPaymentRequest.STATUS_REJECTED:
			raise serializers.ValidationError({'detail': 'Cannot approve a rejected request.'})
		if locked.status != SubscriptionPaymentRequest.STATUS_PENDING:
			raise serializers.ValidationError({'detail': f'Cannot approve request with status "{locked.status}".'})

		locked.status = SubscriptionPaymentRequest.STATUS_APPROVED
		locked.reviewed_by = reviewer
		locked.reviewed_at = timezone.now()
		locked.status_reason_code = reason_code or ''
		locked.status_reason_text = reason_text or ''
		locked.save(
			update_fields=['status', 'reviewed_by', 'reviewed_at', 'status_reason_code', 'status_reason_text']
		)

		subscription = activate_subscription_for_payment_request(locked)
		return locked, True, subscription


def reject_payment_request(payment_request, *, reviewer, reason_code='', reason_text=''):
	"""Reject request idempotently with atomic lock."""
	with transaction.atomic():
		locked = SubscriptionPaymentRequest.objects.select_for_update().get(id=payment_request.id)
		if locked.status == SubscriptionPaymentRequest.STATUS_REJECTED:
			return locked, False
		if locked.status == SubscriptionPaymentRequest.STATUS_APPROVED:
			raise serializers.ValidationError({'detail': 'Cannot reject an approved request.'})
		if locked.status != SubscriptionPaymentRequest.STATUS_PENDING:
			raise serializers.ValidationError({'detail': f'Cannot reject request with status "{locked.status}".'})

		locked.status = SubscriptionPaymentRequest.STATUS_REJECTED
		locked.reviewed_by = reviewer
		locked.reviewed_at = timezone.now()
		locked.status_reason_code = reason_code or SubscriptionPaymentRequest.REASON_OTHER
		locked.status_reason_text = reason_text or ''
		locked.save(
			update_fields=['status', 'reviewed_by', 'reviewed_at', 'status_reason_code', 'status_reason_text']
		)
		return locked, True


def parse_dashboard_date_filters(date_from, date_to, period=None):
	parsed_from = None
	parsed_to = None
	now = timezone.now()

	# Quick presets for faster merchant analytics workflows.
	if period:
		period_key = str(period).strip().lower()
		if period_key in ['today']:
			parsed_from = now.replace(hour=0, minute=0, second=0, microsecond=0)
			parsed_to = now.replace(hour=23, minute=59, second=59, microsecond=999999)
		elif period_key in ['last_7_days', '7d']:
			start = (now - timedelta(days=6)).replace(hour=0, minute=0, second=0, microsecond=0)
			parsed_from = start
			parsed_to = now.replace(hour=23, minute=59, second=59, microsecond=999999)
		elif period_key in ['last_14_days', '14d']:
			start = (now - timedelta(days=13)).replace(hour=0, minute=0, second=0, microsecond=0)
			parsed_from = start
			parsed_to = now.replace(hour=23, minute=59, second=59, microsecond=999999)
		elif period_key in ['last_30_days', '30d']:
			start = (now - timedelta(days=29)).replace(hour=0, minute=0, second=0, microsecond=0)
			parsed_from = start
			parsed_to = now.replace(hour=23, minute=59, second=59, microsecond=999999)
		elif period_key in ['month_to_date', 'mtd']:
			parsed_from = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
			parsed_to = now.replace(hour=23, minute=59, second=59, microsecond=999999)
		else:
			raise serializers.ValidationError({'detail': 'Invalid period. Use today, last_7_days, last_14_days, last_30_days, or month_to_date.'})

	try:
		if date_from:
			parsed_from = datetime.fromisoformat(date_from)
			if timezone.is_naive(parsed_from):
				parsed_from = timezone.make_aware(parsed_from)
		if date_to:
			parsed_to = datetime.fromisoformat(date_to)
			if timezone.is_naive(parsed_to):
				parsed_to = timezone.make_aware(parsed_to)
			parsed_to = parsed_to.replace(hour=23, minute=59, second=59, microsecond=999999)
	except ValueError:
		raise serializers.ValidationError({'detail': 'Invalid date format. Use YYYY-MM-DD.'})
	return parsed_from, parsed_to


def _apply_range_filter(queryset, field_name, parsed_from=None, parsed_to=None):
	if parsed_from is not None:
		queryset = queryset.filter(**{f'{field_name}__gte': parsed_from})
	if parsed_to is not None:
		queryset = queryset.filter(**{f'{field_name}__lte': parsed_to})
	return queryset


def _safe_image_url(request, image_field):
	if not image_field:
		return ''
	try:
		return request.build_absolute_uri(image_field.url)
	except Exception:
		return ''


def build_merchant_dashboard(user, request, *, date_from=None, date_to=None, period=None, parsed_from=None, parsed_to=None, debug=False):
	from analytics.models import InteractionLog
	from catalog.models import Pack, Product, Promotion
	from catalog.serializers import PromotionSerializer
	from ads.models import AdCampaign
	from ads.serializers import AdCampaignSerializer
	from .serializers import MerchantSubscriptionSerializer, SubscriptionPaymentRequestSerializer

	active = get_active_subscription(user)
	plan_features = get_merchant_plan_features(user)
	now = timezone.now()
	days_remaining = max(0, (active.end_date - now).days) if active is not None else None

	promotions_qs = Promotion.objects.filter(store=user).order_by('-created_at')
	promotions_qs = _apply_range_filter(
		promotions_qs,
		'created_at',
		parsed_from=parsed_from,
		parsed_to=parsed_to,
	)
	promotions_data = PromotionSerializer(promotions_qs, many=True).data

	ads_qs = AdCampaign.objects.filter(store=user).order_by('-created_at')
	ads_qs = _apply_range_filter(
		ads_qs,
		'created_at',
		parsed_from=parsed_from,
		parsed_to=parsed_to,
	)
	ads_data = AdCampaignSerializer(ads_qs, many=True).data

	# Product-performance ad counters must reflect real delivered ad views/clicks
	# for the campaign, regardless of campaign creation date filters.
	ads_metrics_qs = AdCampaign.objects.filter(store=user)

	interaction_qs = InteractionLog.objects.filter(product__store=user)
	interaction_qs = _apply_range_filter(
		interaction_qs,
		'timestamp',
		parsed_from=parsed_from,
		parsed_to=parsed_to,
	)

	# Product Performance rules:
	# - Organic metrics (views/clicks/favorites) must EXCLUDE ad-driven sessions.
	# - Stay time must be counted ONLY for ad-driven product details entries.
	organic_counts = defaultdict(lambda: {'views': 0, 'clicks': 0, 'favorites': 0, 'promotion_click_events': 0})
	ad_stay_time_sec = defaultdict(float)
	ad_favorites = defaultdict(int)
	ad_store_clicks = defaultdict(int)
	ad_click_events = defaultdict(int)

	# Follows from advertising traffic.
	# This relies on the app sending metadata['discovery_mode'] == 'advertising'
	# and metadata['product_id'] on follow toggle.
	follows_from_ads = defaultdict(int)

	for row in interaction_qs.values('product_id', 'action', 'metadata').iterator():
		action = row.get('action')
		meta = row.get('metadata') or {}
		discovery_mode = str(meta.get('discovery_mode') or '').strip().lower()
		source_surface = str(meta.get('source_surface') or '').strip().lower()
		is_ad_session = discovery_mode == 'advertising' or source_surface == 'ads'

		# Follow events are store-focused, product id is inside metadata.
		if action == 'follow_store':
			if not is_ad_session:
				continue
			pid = meta.get('product_id')
			try:
				pid_int = int(pid)
			except Exception:
				continue
			follows_from_ads[pid_int] += 1
			continue

		product_id = row.get('product_id')
		if not product_id:
			continue
		try:
			pid_int = int(product_id)
		except Exception:
			continue

		if action == 'view':
			# Stay time: ONLY ad-driven product detail views, SUM total seconds.
			if is_ad_session:
				raw = meta.get('view_duration_sec')
				if raw is None:
					raw = meta.get('duration_seconds')
				try:
					duration = float(raw)
				except Exception:
					duration = 0
				if duration > 0:
					ad_stay_time_sec[pid_int] += duration
				continue
			# Organic view count.
			organic_counts[pid_int]['views'] += 1
			continue

		if action == 'click':
			if is_ad_session:
				ad_click_events[pid_int] += 1
			else:
				organic_counts[pid_int]['clicks'] += 1
			continue

		if action == 'promotion_click':
			if is_ad_session:
				ad_click_events[pid_int] += 1
			else:
				organic_counts[pid_int]['promotion_click_events'] += 1
			continue

		if action == 'favorite':
			if is_ad_session:
				ad_favorites[pid_int] += 1
			else:
				organic_counts[pid_int]['favorites'] += 1
			continue

		if action == 'store_click':
			if is_ad_session:
				ad_store_clicks[pid_int] += 1
			continue

	interaction_map = {pid: data for pid, data in organic_counts.items()}
	product_name_map = {
		int(row['id']): (row.get('name') or '')
		for row in Product.objects.filter(id__in=list(interaction_map.keys())).values('id', 'name')
		if row.get('id')
	}

	promotion_rows = promotions_qs.values('product_id', 'product__name').annotate(
		promotion_count=Count('id'),
	)
	ads_rows = ads_metrics_qs.values('product_id', 'product__name').annotate(
		ad_count=Count('id'),
		ad_impressions=Sum('impressions_count'),
		ad_clicks=Sum('clicks_count'),
		ad_unique_viewers=Sum('unique_viewers_count'),
	)
	promotion_map = {
		int(row['product_id']): row
		for row in promotion_rows
		if row.get('product_id')
	}
	ads_map = {
		int(row['product_id']): row
		for row in ads_rows
		if row.get('product_id')
	}

	product_ids = set(interaction_map.keys()) | set(promotion_map.keys()) | set(ads_map.keys())
	product_stats = []
	for product_id in product_ids:
		interaction_row = interaction_map.get(product_id, {})
		promotion_row = promotion_map.get(product_id, {})
		ad_row = ads_map.get(product_id, {})
		ad_impressions = int(ad_row.get('ad_impressions') or 0)
		ad_clicks = int(ad_row.get('ad_clicks') or 0)
		ad_clicks = max(ad_clicks, int(ad_click_events.get(product_id, 0) or 0))
		product_stats.append(
			{
				'product_id': product_id,
				'product_name': (
					product_name_map.get(product_id)
					or ad_row.get('product__name')
					or promotion_row.get('product__name')
					or ''
				),
				'views': int(interaction_row.get('views') or 0),
				'clicks': int(interaction_row.get('clicks') or 0),
				'favorites': int(interaction_row.get('favorites') or 0),
				'ad_favorites': int(ad_favorites.get(product_id, 0) or 0),
				'ad_stay_time_sec': float(round(ad_stay_time_sec.get(product_id, 0.0) or 0.0, 2)),
				'store_clicks_from_ads': int(ad_store_clicks.get(product_id, 0) or 0),
				'follows_from_ads': int(follows_from_ads.get(product_id, 0) or 0),
				'promotion_click_events': int(interaction_row.get('promotion_click_events') or 0),
				'ad_count': int(ad_row.get('ad_count') or 0),
				'promotion_count': int(promotion_row.get('promotion_count') or 0),
				'ad_impressions': ad_impressions,
				'ad_clicks': ad_clicks,
				'ad_unique_viewers': int(ad_row.get('ad_unique_viewers') or 0),
				'ad_ctr': round((ad_clicks / ad_impressions) * 100, 2) if ad_impressions > 0 else 0.0,
			}
		)
	product_stats.sort(
		key=lambda row: (row['ad_impressions'], row['ad_clicks'], row['views'], row['clicks']),
		reverse=True,
	)

	active_ads_qs = ads_qs.filter(
		is_active=True,
	)
	active_ad_campaign_id_by_product = {}
	for row in (
		active_ads_qs.filter(product_id__isnull=False)
		.order_by('-created_at')
		.values('product_id', 'id')
	):
		pid = row.get('product_id')
		cid = row.get('id')
		if pid and cid and int(pid) not in active_ad_campaign_id_by_product:
			active_ad_campaign_id_by_product[int(pid)] = int(cid)
	active_ad_counts = {
		int(row['product_id']): int(row['active_ad_count'] or 0)
		for row in active_ads_qs.values('product_id').annotate(active_ad_count=Count('id'))
		if row.get('product_id')
	}
	active_pack_ad_counts = {
		int(row['pack_id']): int(row['active_ad_count'] or 0)
		for row in active_ads_qs.values('pack_id').annotate(active_ad_count=Count('id'))
		if row.get('pack_id')
	}
	ad_max_active = int(plan_features.get('ad_max_active') or 0)
	cfg = get_coin_configuration()
	ad_view_cost = int(cfg['ad_view_cost'])
	user_ad_view_coins = int(getattr(user, 'coins_balance', 0) or 0)
	active_total = int(sum(active_ad_counts.values())) + int(sum(active_pack_ad_counts.values()))
	remaining_slots = max(ad_max_active - active_total, 0)
	ad_inventory = {
		'ad_enabled': True,
		'ad_max_active': None,
		'ad_active_count': active_total,
		'remaining_ad_slots': None,
		'ad_max_impressions': None,
		'remaining_plan_impressions': user_ad_view_coins // max(ad_view_cost, 1),
		'ad_view_coins_balance': user_ad_view_coins,
		'ad_view_coin_cost': ad_view_cost,
	}

	products_qs = Product.objects.filter(store=user).prefetch_related('images').order_by('-created_at')
	eligible_products = []
	for product in products_qs:
		product_image = next(iter(product.images.all()), None)
		eligible_products.append(
			{
				'id': product.id,
				'name': product.name,
				'price': str(product.price),
				'image': _safe_image_url(request, getattr(product_image, 'image', None)),
				'has_active_ad': active_ad_counts.get(product.id, 0) > 0,
				'active_ad_count': active_ad_counts.get(product.id, 0),
				'active_ad_campaign_id': active_ad_campaign_id_by_product.get(product.id),
			}
		)

	packs_qs = Pack.objects.filter(merchant=user).prefetch_related('images').order_by('-created_at')
	eligible_packs = []
	for pack in packs_qs:
		pack_image = next(iter(pack.images.all()), None)
		eligible_packs.append(
			{
				'id': pack.id,
				'name': pack.name,
				'price': str(pack.discount),
				'image': _safe_image_url(request, getattr(pack_image, 'image', None)),
				'has_active_ad': active_pack_ad_counts.get(pack.id, 0) > 0,
				'active_ad_count': active_pack_ad_counts.get(pack.id, 0),
			}
		)

	latest_request = (
		SubscriptionPaymentRequest.objects.select_related('plan')
		.filter(merchant=user)
		.order_by('-created_at')
		.first()
	)

	result = {
		'active_subscription': MerchantSubscriptionSerializer(active).data if active is not None else None,
		'days_remaining': days_remaining,
		'plan_features': plan_features,
		'coin_wallet': get_coin_wallet_snapshot(user),
		'ad_inventory': ad_inventory,
		'filters': {
			'date_from': date_from,
			'date_to': date_to,
			'period': period,
		},
		'latest_payment_request': (
			SubscriptionPaymentRequestSerializer(latest_request).data
			if latest_request is not None
			else None
		),
		'promotions': promotions_data,
		'ads': ads_data,
		'product_stats': product_stats,
		'eligible_products': eligible_products,
		'eligible_packs': eligible_packs,
	}

	if debug:
		result['debug'] = {
			'date_from': date_from,
			'date_to': date_to,
			'period': period,
			'ads_qs_count': int(ads_qs.count()),
			'ads_raw_impressions_sum': int(ads_qs.aggregate(v=Sum('impressions_count')).get('v') or 0),
			'ads_raw_clicks_sum': int(ads_qs.aggregate(v=Sum('clicks_count')).get('v') or 0),
			'interaction_qs_count': int(interaction_qs.count()),
			'product_stats_count': len(product_stats),
			'product_stats_preview': [
				{
					'product_id': row.get('product_id'),
					'product_name': row.get('product_name'),
					'ad_impressions': row.get('ad_impressions'),
					'ad_clicks': row.get('ad_clicks'),
					'ad_favorites': row.get('ad_favorites'),
					'ad_stay_time_sec': row.get('ad_stay_time_sec'),
				}
				for row in product_stats[:10]
			],
		}

	return result
