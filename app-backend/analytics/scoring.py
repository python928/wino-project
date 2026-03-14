import logging
from collections import defaultdict
from datetime import timedelta

from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone

from analytics.models import InteractionLog, UserInterestProfile
from analytics.utils import (
	ACTION_CONTRIBUTIONS,
	calculate_time_decay,
	get_price_range,
	normalize_discovery_mode,
)

logger = logging.getLogger(__name__)
User = get_user_model()

ENGAGEMENT_ACTIONS = {
	'view',
	'click',
	'promotion_click',
	'search',
	'filter_price',
	'filter_dist',
	'filter_wilaya',
	'filter_rating',
	'favorite',
	'compare',
	'contact',
	'negotiate',
	'share',
	'rate',
	'follow_store',
}


def _safe_float(value):
	try:
		return float(value)
	except Exception:
		return None


def _safe_int(value):
	try:
		return int(value)
	except Exception:
		return None


def update_user_profile(user):
	profile, _created = UserInterestProfile.objects.get_or_create(user=user)

	lookback_days = getattr(settings, 'ANALYTICS_LOOKBACK_DAYS', 30)
	since_dt = timezone.now() - timedelta(days=int(lookback_days))

	interactions = InteractionLog.objects.filter(
		user=user,
		timestamp__gte=since_dt,
	).select_related('product', 'category', 'product__category')

	if not interactions.exists():
		return profile

	category_scores = defaultdict(float)
	store_category_scores = defaultdict(float)
	nearby_distances = []
	wilaya_scores = defaultdict(float)
	search_keywords = defaultdict(float)
	seller_scores = defaultdict(float)
	price_filter_ranges = []

	for interaction in interactions:
		if interaction.action not in ENGAGEMENT_ACTIONS:
			continue

		meta = interaction.metadata or {}
		cat_id = None
		if interaction.category_id:
			cat_id = str(interaction.category_id)
		elif interaction.product_id and interaction.product and interaction.product.category_id:
			cat_id = str(interaction.product.category_id)

		action_profile = ACTION_CONTRIBUTIONS.get(interaction.action, ACTION_CONTRIBUTIONS['view']).copy()
		if interaction.action == 'view':
			view_duration_sec = _safe_float(meta.get('view_duration_sec'))
			if view_duration_sec is not None and view_duration_sec > 0:
				# 0s->1.0x, 120s+->2.0x (capped), rewarding meaningful dwell time.
				duration_factor = 1.0 + min(view_duration_sec, 120.0) / 120.0
				for k in list(action_profile.keys()):
					action_profile[k] *= duration_factor
		if interaction.action == 'rate':
			rating_value = _safe_float(meta.get('rating'))
			if rating_value is None:
				rating_value = _safe_float(getattr(interaction, 'rating', None))
			if rating_value is None:
				rating_value = 3.0
			rating_value = max(1.0, min(5.0, rating_value))
			action_profile['category'] *= rating_value
			action_profile['store_category'] *= rating_value
			action_profile['seller'] *= rating_value
			action_profile['mode'] *= rating_value

		decay = calculate_time_decay(interaction.timestamp)

		# Filter events without product context
		if interaction.action == 'filter_dist':
			distance_km = _safe_float(meta.get('distance_km'))
			if distance_km is not None and distance_km >= 0:
				nearby_distances.append((distance_km, action_profile.get('mode', 0.0) * decay))
		if interaction.action == 'filter_wilaya':
			wilaya_code = str(meta.get('wilaya_code') or meta.get('wilaya') or '').strip()
			if wilaya_code:
				wilaya_scores[wilaya_code] += action_profile.get('mode', 0.0) * decay
		if interaction.action == 'filter_price':
			price_range = str(meta.get('price_range') or '').strip()
			if not price_range:
				min_p = _safe_float(meta.get('price_min'))
				max_p = _safe_float(meta.get('price_max'))
				if min_p is not None or max_p is not None:
					anchor = min_p if min_p is not None else max_p
					try:
						price_range = get_price_range(anchor)
					except Exception:
						price_range = ''
			if price_range:
				price_filter_ranges.append((price_range, action_profile.get('category', 0.0) * decay))

		if cat_id:
			category_scores[cat_id] += action_profile.get('category', 0.0) * decay

		store_id = None
		if interaction.product_id and interaction.product:
			store_id = getattr(interaction.product, 'store_id', None)
		if store_id is None:
			store_id = _safe_int(meta.get('store_id'))
		if store_id:
			seller_scores[int(store_id)] += action_profile.get('seller', 0.0) * decay
			if cat_id:
				store_category_scores[(int(store_id), cat_id)] += action_profile.get('store_category', 0.0) * decay

		discovery_mode = normalize_discovery_mode(meta.get('discovery_mode'))
		mode_weight = action_profile.get('mode', 0.0) * decay
		if discovery_mode == 'nearby' and mode_weight > 0:
			distance_km = _safe_float(meta.get('distance_km'))
			if distance_km is not None and distance_km >= 0:
				nearby_distances.append((distance_km, mode_weight))
		elif discovery_mode == 'location' and mode_weight > 0:
			wilaya_code = str(meta.get('wilaya_code') or meta.get('wilaya') or '').strip()
			if wilaya_code:
				wilaya_scores[wilaya_code] += mode_weight

		keyword = str(meta.get('search_query') or meta.get('keyword') or '').strip().lower()
		if keyword:
			search_keywords[keyword] += max(1.0, action_profile.get('category', 0.0)) * decay

	profile.category_scores = dict(category_scores)

	price_affinity = defaultdict(float)
	price_relevant_actions = ['view', 'click', 'contact', 'favorite', 'negotiate', 'compare', 'rate']

	for interaction in interactions:
		if interaction.action in price_relevant_actions and interaction.product and interaction.product.price:
			try:
				price = float(interaction.product.price)
				if price > 0 and not getattr(interaction.product, 'hide_price', False):
					range_name = get_price_range(price)
					weight = ACTION_CONTRIBUTIONS.get(interaction.action, ACTION_CONTRIBUTIONS['view']).get('category', 1.0)
					if interaction.action == 'rate':
						rating_value = _safe_float((interaction.metadata or {}).get('rating'))
						if rating_value is not None:
							weight *= max(1.0, min(5.0, rating_value))
					decay = calculate_time_decay(interaction.timestamp)
					price_affinity[range_name] += weight * decay
			except Exception:
				pass

	for range_name, weight in price_filter_ranges:
		price_affinity[range_name] += weight

	profile.price_affinity = dict(price_affinity)

	if nearby_distances:
		total_weight = sum(w for _, w in nearby_distances)
		if total_weight > 0:
			profile.preferred_max_distance_km = sum(d * w for d, w in nearby_distances) / total_weight
		profile.distance_sensitivity = min(5.0, 1.0 + (total_weight / 12.0))
	else:
		profile.distance_sensitivity = 1.0

	if wilaya_scores:
		sorted_wilayas = sorted(wilaya_scores.items(), key=lambda x: x[1], reverse=True)
		profile.preferred_wilayas = [w[0] for w in sorted_wilayas[:10]]

	if search_keywords:
		sorted_kw = sorted(search_keywords.items(), key=lambda x: x[1], reverse=True)
		profile.search_keywords = dict(sorted_kw[:20])

	rating_events = interactions.filter(action='rate').count()
	profile.quality_sensitivity = min(5.0, 1.0 + (rating_events * 0.1))

	for (seller_id, cat_id), score in store_category_scores.items():
		seller_scores[seller_id] += score * 0.2
	if seller_scores:
		sorted_sellers = sorted(seller_scores.items(), key=lambda x: x[1], reverse=True)
		profile.preferred_sellers = [s[0] for s in sorted_sellers[:10]]

	profile.save()
	return profile


def update_all_profiles():
	lookback_days = getattr(settings, 'ANALYTICS_LOOKBACK_DAYS', 30)
	since_dt = timezone.now() - timedelta(days=int(lookback_days))

	active_user_ids = InteractionLog.objects.filter(
		timestamp__gte=since_dt,
	).values_list('user_id', flat=True).distinct()

	updated = 0
	for user_id in active_user_ids:
		try:
			user = User.objects.get(id=user_id)
			update_user_profile(user)
			updated += 1
		except User.DoesNotExist:
			continue
		except Exception as e:
			logger.error(f"Error updating profile for user {user_id}: {e}")

	logger.info(f"Updated {updated} user profiles")
	return updated
