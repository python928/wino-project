import logging
from collections import defaultdict
from datetime import timedelta

from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone

from analytics.models import InteractionLog, UserInterestProfile
from analytics.utils import INTERACTION_WEIGHTS, calculate_time_decay, get_price_range

logger = logging.getLogger(__name__)
User = get_user_model()


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
	for interaction in interactions:
		cat_id = None
		if interaction.category_id:
			cat_id = str(interaction.category_id)
		elif interaction.product_id and interaction.product and interaction.product.category_id:
			cat_id = str(interaction.product.category_id)

		if not cat_id:
			continue

		weight = INTERACTION_WEIGHTS.get(interaction.action, 1)
		decay = calculate_time_decay(interaction.timestamp)
		category_scores[cat_id] += weight * decay

	profile.category_scores = dict(category_scores)

	price_affinity = defaultdict(float)
	price_relevant_actions = ['view', 'click', 'contact', 'favorite', 'negotiate', 'compare']

	for interaction in interactions:
		if interaction.action in price_relevant_actions and interaction.product and interaction.product.price:
			try:
				price = float(interaction.product.price)
				if price > 0 and not getattr(interaction.product, 'hide_price', False):
					range_name = get_price_range(price)
					weight = INTERACTION_WEIGHTS.get(interaction.action, 1)
					decay = calculate_time_decay(interaction.timestamp)
					price_affinity[range_name] += weight * decay
			except Exception:
				pass

		if interaction.action == 'filter_price':
			meta = interaction.metadata or {}
			if 'min' in meta and 'max' in meta:
				try:
					avg_price = (float(meta['min']) + float(meta['max'])) / 2
					range_name = get_price_range(avg_price)
					price_affinity[range_name] += 3 * calculate_time_decay(interaction.timestamp)
				except Exception:
					pass

	profile.price_affinity = dict(price_affinity)

	dist_filter_count = interactions.filter(action='filter_dist').count()
	profile.distance_sensitivity = 1.0 + (dist_filter_count * 0.1)

	dist_interactions = interactions.filter(action='filter_dist')
	if dist_interactions.exists():
		distances = []
		for inter in dist_interactions:
			km = (inter.metadata or {}).get('km')
			if km is None:
				continue
			try:
				distances.append(float(km))
			except Exception:
				continue
		if distances:
			profile.preferred_max_distance_km = sum(distances) / len(distances)

	rating_filter_count = interactions.filter(action='filter_rating').count()
	profile.quality_sensitivity = 1.0 + (rating_filter_count * 0.15)

	wilaya_interactions = interactions.filter(action='filter_wilaya')
	wilaya_counts = defaultdict(int)
	for inter in wilaya_interactions:
		code = (inter.metadata or {}).get('wilaya_code')
		if code:
			wilaya_counts[str(code)] += 1
	if wilaya_counts:
		sorted_wilayas = sorted(wilaya_counts.items(), key=lambda x: x[1], reverse=True)
		profile.preferred_wilayas = [w[0] for w in sorted_wilayas[:10]]

	search_interactions = interactions.filter(action='search')
	keywords = defaultdict(int)
	for inter in search_interactions:
		kw = (inter.metadata or {}).get('keyword', '')
		kw = str(kw).strip().lower()
		if kw:
			keywords[kw] += 1
	if keywords:
		sorted_kw = sorted(keywords.items(), key=lambda x: x[1], reverse=True)
		profile.search_keywords = dict(sorted_kw[:20])

	seller_scores = defaultdict(float)
	strong_actions = ['contact', 'negotiate', 'favorite']
	for interaction in interactions:
		if interaction.action in strong_actions and interaction.product_id and interaction.product:
			seller_id = getattr(interaction.product, 'store_id', None)
			if seller_id:
				weight = INTERACTION_WEIGHTS.get(interaction.action, 1)
				seller_scores[int(seller_id)] += weight

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
