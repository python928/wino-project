from decimal import Decimal

from django.conf import settings
from django.db import transaction
from django.db.models import F
from django.utils import timezone
from rest_framework import serializers

from .models import CoinPurchase, CoinTransaction


def _get_setting(name, default):
	value = getattr(settings, name, default)
	try:
		return int(value)
	except Exception:
		return int(default)


def get_coin_costs():
	return {
		'product': _get_setting('COST_PRODUCT_POST_COINS', 5),
		'pack': _get_setting('COST_PACK_POST_COINS', 7),
		'promotion': _get_setting('COST_PROMOTION_POST_COINS', 4),
		'ad_view': _get_setting('COST_AD_VIEW_COIN', 1),
	}


def _insufficient_error(required, balance):
	raise serializers.ValidationError(
		{
			'code': 'INSUFFICIENT_COINS',
			'required': int(required),
			'balance': int(balance),
		}
	)


def grant_coins(user, *, amount, reason='admin_grant', related_model='', related_id=None):
	amount = int(amount or 0)
	if amount <= 0:
		return
	field_name = 'coins_balance'
	with transaction.atomic():
		type(user).objects.filter(id=user.id).update(**{field_name: F(field_name) + amount})
		CoinTransaction.objects.create(
			user=user,
			amount_signed=amount,
			reason=reason,
			related_model=related_model or '',
			related_id=related_id,
		)
	user.refresh_from_db(fields=[field_name])


def consume_coins(user, *, amount, reason, related_model='', related_id=None):
	amount = int(amount or 0)
	if amount <= 0:
		return
	field_name = 'coins_balance'
	with transaction.atomic():
		locked = type(user).objects.select_for_update().only(field_name).get(id=user.id)
		current = int(getattr(locked, field_name, 0) or 0)
		if current < amount:
			_insufficient_error(amount, current)
		type(user).objects.filter(id=user.id).update(**{field_name: F(field_name) - amount})
		CoinTransaction.objects.create(
			user=user,
			amount_signed=-amount,
			reason=reason,
			related_model=related_model or '',
			related_id=related_id,
		)
	user.refresh_from_db(fields=[field_name])


def ensure_can_create_post(user, post_type, related_model='', related_id=None):
	costs = get_coin_costs()
	cost = int(costs.get(post_type, 0))
	if cost <= 0:
		return 0
	consume_coins(
		user,
		amount=cost,
		reason=f'{post_type}_create',
		related_model=related_model,
		related_id=related_id,
	)
	return cost


def consume_ad_view_coin(user, *, campaign, is_unique_viewer=False, viewer_key=''):
	field_name = 'coins_balance'
	with transaction.atomic():
		locked = type(user).objects.select_for_update().only(field_name).get(id=user.id)
		current = int(getattr(locked, field_name, 0) or 0)
		if current <= 0:
			# Count the delivered impression for analytics even if billing cannot be charged.
			update_fields = {
				'impressions_count': F('impressions_count') + 1,
				'delivered_views_count': F('delivered_views_count') + 1,
			}
			if is_unique_viewer:
				update_fields['unique_viewers_count'] = F('unique_viewers_count') + 1
			campaign.__class__.objects.filter(id=campaign.id).update(**update_fields)
			campaign.__class__.objects.filter(id=campaign.id).update(is_active=False)
			return False
		new_balance = current - 1
		type(user).objects.filter(id=user.id).update(**{field_name: F(field_name) - 1})
		CoinTransaction.objects.create(
			user=user,
			amount_signed=-1,
			reason='ad_view',
			related_model='AdCampaign',
			related_id=campaign.id,
		)
		update_fields = {
			'impressions_count': F('impressions_count') + 1,
			'delivered_views_count': F('delivered_views_count') + 1,
		}
		if is_unique_viewer:
			update_fields['unique_viewers_count'] = F('unique_viewers_count') + 1
		campaign.__class__.objects.filter(id=campaign.id).update(**update_fields)
		campaign.__class__.objects.filter(
			id=campaign.id,
			max_impressions__isnull=False,
			impressions_count__gte=F('max_impressions'),
		).update(is_active=False)
		if new_balance <= 0:
			campaign.__class__.objects.filter(id=campaign.id).update(is_active=False)
	user.refresh_from_db(fields=[field_name])
	return True


def get_wallet_snapshot(user, limit=20):
	transactions = CoinTransaction.objects.filter(user=user).order_by('-created_at')[:limit]
	purchases = CoinPurchase.objects.filter(user=user).order_by('-created_at')[:limit]
	balance = int(getattr(user, 'coins_balance', 0) or 0)
	return {
		'coins_balance': balance,
		# Legacy keys are kept for backward compatibility in older app widgets.
		'post_coins_balance': balance,
		'ad_view_coins_balance': balance,
		'recent_transactions': transactions,
		'recent_purchases': purchases,
	}


def create_coin_purchase(user, *, pack_id, coins_amount, price_amount, payment_note=''):
	return CoinPurchase.objects.create(
		user=user,
		pack_id=pack_id or '',
		coins_amount=int(coins_amount or 0),
		price_amount=Decimal(price_amount or 0),
		payment_note=str(payment_note or ''),
		status=CoinPurchase.STATUS_PENDING,
	)


def approve_coin_purchase(purchase, *, approver=None):
	"""Approve a pending purchase and grant coins exactly once."""
	with transaction.atomic():
		locked = CoinPurchase.objects.select_for_update().get(id=purchase.id)
		if locked.status == CoinPurchase.STATUS_COMPLETED:
			return locked, False
		if locked.status != CoinPurchase.STATUS_PENDING:
			raise serializers.ValidationError(
				{'detail': f'Cannot approve purchase with status "{locked.status}".'}
			)

		grant_coins(
			locked.user,
			amount=locked.coins_amount,
			reason='purchase_approved',
			related_model='CoinPurchase',
			related_id=locked.id,
		)

		locked.status = CoinPurchase.STATUS_COMPLETED
		locked.approved_at = timezone.now()
		if approver is not None:
			locked.approved_by = approver
		locked.save(update_fields=['status', 'approved_at', 'approved_by'])
		return locked, True


def reject_coin_purchase(purchase, *, approver=None, reason=''):
	"""Reject a pending purchase exactly once in an idempotent way."""
	with transaction.atomic():
		locked = CoinPurchase.objects.select_for_update().get(id=purchase.id)
		if locked.status == CoinPurchase.STATUS_FAILED:
			return locked, False
		if locked.status == CoinPurchase.STATUS_COMPLETED:
			raise serializers.ValidationError(
				{'detail': 'Cannot reject a completed purchase.'}
			)
		if locked.status != CoinPurchase.STATUS_PENDING:
			raise serializers.ValidationError(
				{'detail': f'Cannot reject purchase with status "{locked.status}".'}
			)

		locked.status = CoinPurchase.STATUS_FAILED
		locked.approved_at = timezone.now()
		if approver is not None:
			locked.approved_by = approver
		if reason:
			locked.payment_note = f"{locked.payment_note}\n[ADMIN_REJECT] {reason}".strip()
		locked.save(update_fields=['status', 'approved_at', 'approved_by', 'payment_note'])
		return locked, True
