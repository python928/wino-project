import logging
import math

from django.conf import settings
from django.utils import timezone

logger = logging.getLogger(__name__)


INTERACTION_WEIGHTS = {
	'view': 1,
	'click': 2,
	'search': 3,
	'filter_price': 3,
	'filter_dist': 3,
	'filter_wilaya': 3,
	'filter_rating': 3,
	'share': 4,
	'favorite': 5,
	'compare': 6,
	'negotiate': 8,
	'contact': 10,
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
		if product and getattr(product, 'category_id', None):
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
