import logging
import math

from django.conf import settings
from django.utils import timezone

logger = logging.getLogger(__name__)


INTERACTION_WEIGHTS = {
	'view': 1,
	'click': 2,
	'promotion_click': 2,
	'search': 0,
	'filter_price': 3,
	'filter_dist': 3,
	'filter_wilaya': 3,
	'filter_rating': 3,
	'share': 4,
	'favorite': 5,
	'compare': 6,
	'negotiate': 8,
	'contact': 10,
	'rate': 6,
	'follow_store': 5,
}

# Per-action contribution profile used by scoring.update_user_profile().
# Values are base contributions before recency decay.
ACTION_CONTRIBUTIONS = {
	'view': {'category': 1.0, 'mode': 1.0, 'store_category': 1.0, 'seller': 0.8},
	'click': {'category': 1.5, 'mode': 1.0, 'store_category': 1.2, 'seller': 1.0},
	'promotion_click': {'category': 1.4, 'mode': 1.0, 'store_category': 1.1, 'seller': 1.0},
	'search': {'category': 0.4, 'mode': 0.2, 'store_category': 0.0, 'seller': 0.0},
	'filter_price': {'category': 0.3, 'mode': 0.0, 'store_category': 0.0, 'seller': 0.0},
	'filter_dist': {'category': 0.1, 'mode': 1.2, 'store_category': 0.0, 'seller': 0.0},
	'filter_wilaya': {'category': 0.1, 'mode': 1.0, 'store_category': 0.0, 'seller': 0.0},
	'filter_rating': {'category': 0.2, 'mode': 0.0, 'store_category': 0.0, 'seller': 0.0},
	'favorite': {'category': 4.0, 'mode': 2.0, 'store_category': 3.0, 'seller': 3.5},
	'compare': {'category': 2.5, 'mode': 1.5, 'store_category': 2.0, 'seller': 1.5},
	'contact': {'category': 6.0, 'mode': 3.0, 'store_category': 5.0, 'seller': 6.0},
	'negotiate': {'category': 5.5, 'mode': 3.0, 'store_category': 4.5, 'seller': 5.0},
	'share': {'category': 2.0, 'mode': 1.2, 'store_category': 1.5, 'seller': 1.5},
	'rate': {'category': 1.0, 'mode': 0.6, 'store_category': 1.0, 'seller': 0.8},
	'follow_store': {'category': 0.0, 'mode': 0.0, 'store_category': 2.0, 'seller': 5.0},
}

PRICE_RANGES = {
	'very_low': (0, 2000),
	'low': (2000, 5000),
	'medium': (5000, 30000),
	'high': (30000, 100000),
	'very_high': (100000, float('inf')),
}


def get_price_range(price):
	price = float(price)
	for range_name, (low, high) in PRICE_RANGES.items():
		if low <= price < high:
			return range_name
	return 'very_high'


def calculate_time_decay(interaction_date, half_life_days=None):
	if half_life_days is None:
		half_life_days = getattr(settings, 'ANALYTICS_TIMEDECAY_HALF_LIFE_DAYS', 14)

	now = timezone.now()
	age_days = (now - interaction_date).days
	decay = math.pow(0.5, age_days / float(half_life_days))
	return max(decay, 0.01)


def log_user_event(user, action, product=None, metadata=None, session_id=''):
	"""Best-effort logging. Never raise, never break main request flow."""

	if metadata is None:
		metadata = {}

	if not user or not getattr(user, 'is_authenticated', False):
		return None

	try:
		from analytics.models import InteractionLog

		category = None
		if metadata and metadata.get('category_id'):
			try:
				from catalog.models import Category
				category = Category.objects.filter(id=metadata.get('category_id')).first()
			except Exception:
				category = None
		elif product and getattr(product, 'category_id', None):
			category = product.category

		log_entry = InteractionLog.objects.create(
			user=user,
			product=product,
			category=category,
			action=action,
			metadata=metadata,
			session_id=session_id or '',
		)
		return log_entry
	except Exception as e:
		logger.error(f"Failed to log user event: {e}")
		return None


def normalize_discovery_mode(value):
	"""Normalize location discovery mode sent by the app."""
	raw = str(value or '').strip().lower()
	if raw in {'nearby', 'distance'}:
		return 'nearby'
	if raw in {'location', 'area', 'wilaya'}:
		return 'location'
	return 'none'
