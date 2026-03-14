import logging
import random
from collections import defaultdict
from datetime import timedelta
from math import asin, cos, radians, sin, sqrt

from django.conf import settings
from django.db import models
from django.db.models import Avg, Q
from django.utils import timezone

from analytics.models import InteractionLog, UserInterestProfile
from analytics.utils import get_price_range

logger = logging.getLogger(__name__)


SCORE_WEIGHTS = {
	'category': 0.22,
	'price': 0.11,
	'quality': 0.11,
	'recency': 0.08,
	'popularity': 0.07,
	'seller_trust': 0.07,
	'seller_affinity': 0.09,
	'personal_engagement': 0.09,
	'session_intent': 0.06,
	'location_pref': 0.05,
	'keyword_match': 0.05,
	'novelty': 0.04,
	'negotiable': 0.03,
	'promotion': 0.03,
	'ad_boost': 0.06,
}


def get_recommended_products(user, limit=20, category_filter=None):
	from catalog.models import Product

	try:
		profile = UserInterestProfile.objects.get(user=user)
	except UserInterestProfile.DoesNotExist:
		return _get_popular_products(
			limit,
			preferred_wilayas=_get_user_wilayas(user),
			user=user,
		)

	top_categories = profile.get_top_categories(limit=7)
	preferred_sellers = [int(s) for s in (profile.preferred_sellers or []) if str(s).isdigit()]
	preferred_wilayas = profile.preferred_wilayas or []
	search_keywords = list((profile.search_keywords or {}).keys())
	session_context = _get_session_context(user)

	qs = Product.objects.filter().select_related('store', 'category').prefetch_related('images', 'reviews', 'promotions')

	# Best-effort: handle AVAILABLE constant if present, else just return all.
	if hasattr(Product, 'AVAILABLE') and hasattr(Product, 'available_status'):
		qs = qs.filter(available_status=Product.AVAILABLE)

	if getattr(user, 'id', None):
		qs = qs.exclude(store_id=user.id)

	if category_filter:
		qs = qs.filter(category_id=category_filter)
	elif top_categories:
		qs = qs.filter(
			Q(category_id__in=top_categories)
			| Q(category__parent_id__in=top_categories)
			| Q(store_id__in=preferred_sellers)
		)

	candidates = list(qs[:350])
	if not candidates:
		return _get_popular_products(limit, preferred_wilayas=preferred_wilayas, user=user)

	now = timezone.now()
	candidate_ids = [p.id for p in candidates]

	popularity_rows = (
		InteractionLog.objects.filter(
			product_id__in=candidate_ids,
			timestamp__gte=now - timedelta(days=14),
		)
		.values('product_id')
		.annotate(count=models.Count('id'))
	)
	popularity_map = {int(r['product_id']): int(r['count']) for r in popularity_rows}
	max_popularity = max(popularity_map.values()) if popularity_map else 1

	user_rows = (
		InteractionLog.objects.filter(
			user=user,
			product_id__in=candidate_ids,
			timestamp__gte=now - timedelta(days=60),
		)
		.values('product_id', 'action')
		.annotate(count=models.Count('id'))
	)
	action_strength = {
		'view': 1.0,
		'click': 1.2,
		'favorite': 4.0,
		'rate': 4.5,
		'contact': 5.0,
		'negotiate': 4.5,
		'share': 2.0,
		'compare': 2.2,
		'follow_store': 3.0,
	}
	user_product_engagement = defaultdict(float)
	for row in user_rows:
		pid = int(row['product_id'])
		action = row['action']
		count = int(row['count'] or 0)
		user_product_engagement[pid] += action_strength.get(action, 1.0) * count
	max_user_engagement = max(user_product_engagement.values()) if user_product_engagement else 1

	scored = []
	for product in candidates:
		breakdown = _calculate_product_score(
			product,
			profile,
			popularity_count=popularity_map.get(product.id, 0),
			max_popularity=max_popularity,
			user_engagement=user_product_engagement.get(product.id, 0),
			max_user_engagement=max_user_engagement,
			preferred_wilayas=preferred_wilayas,
			keywords=search_keywords,
			session_context=session_context,
			user=user,
		)
		final_score = 0.0
		for key, weight in SCORE_WEIGHTS.items():
			final_score += float(breakdown.get(key, 0)) * float(weight)
		scored.append({
			'product': product,
			'score': round(final_score, 2),
			'breakdown': breakdown,
			'match_reasons': _get_match_reasons(breakdown),
		})

	recently_viewed = set(
		InteractionLog.objects.filter(
			user=user,
			action='view',
			timestamp__gte=timezone.now() - timezone.timedelta(hours=8),
		).values_list('product_id', flat=True)
	)

	filtered_scored = [sp for sp in scored if sp['product'].id not in recently_viewed]
	# In tiny catalogs, strict recency filtering can empty the feed.
	# Fall back to original scored list instead of returning nothing.
	if filtered_scored:
		scored = filtered_scored

	scored.sort(key=lambda x: x['score'], reverse=True)
	scored = _apply_smart_exploration(scored, user=user, limit=limit)
	results = _diversify_results(scored, max_per_seller=3, max_per_category=4)[:limit]

	# Keep the feed populated even when personalization has few candidates.
	if len(results) < limit:
		seen_ids = {item['product'].id for item in results if item.get('product')}
		for candidate in _get_popular_products(
			limit=max(limit * 2, 20),
			preferred_wilayas=preferred_wilayas,
			user=user,
		):
			product = candidate.get('product')
			if not product:
				continue
			if getattr(user, 'id', None) and product.store_id == user.id:
				continue
			if product.id in seen_ids:
				continue
			results.append(candidate)
			seen_ids.add(product.id)
			if len(results) >= limit:
				break

	return results[:limit]


def get_similar_products(product, limit=10):
	from catalog.models import Product

	qs = Product.objects.filter(category=product.category).exclude(id=product.id).select_related('store', 'category')

	if hasattr(Product, 'AVAILABLE') and hasattr(Product, 'available_status'):
		qs = qs.filter(available_status=Product.AVAILABLE)

	if getattr(product, 'price', None):
		try:
			price = float(product.price)
			price_range = price * 0.3
			qs = qs.filter(price__gte=price - price_range, price__lte=price + price_range)
		except Exception:
			pass

	return qs.order_by('-id')[:limit]


def _calculate_product_score(
	product,
	profile,
	popularity_count=0,
	max_popularity=1,
	user_engagement=0,
	max_user_engagement=1,
	preferred_wilayas=None,
	keywords=None,
	session_context=None,
	user=None,
):
	scores = {}
	preferred_wilayas = preferred_wilayas or []
	keywords = keywords or []
	session_context = session_context or {}

	cat_id = str(getattr(product, 'category_id', '') or '')
	if cat_id and cat_id in (profile.category_scores or {}):
		max_cat_score = max(profile.category_scores.values()) if profile.category_scores else 1
		scores['category'] = min((profile.category_scores[cat_id] / max_cat_score) * 100, 100)
	else:
		scores['category'] = 0

	if getattr(product, 'price', None) and not getattr(product, 'hide_price', False):
		try:
			product_range = get_price_range(product.price)
			preferred_range = profile.get_price_range_preference()
			if product_range == preferred_range:
				scores['price'] = 100
			elif _ranges_adjacent(product_range, preferred_range):
				scores['price'] = 60
			else:
				scores['price'] = 20
		except Exception:
			scores['price'] = 50
	else:
		scores['price'] = 50

	# Product rating: if Review model/related_name differs, fallback gracefully.
	avg_rating = None
	review_count = 0
	for rel in ['reviews', 'product_reviews']:
		if hasattr(product, rel):
			try:
				avg_rating = getattr(product, rel).aggregate(avg=Avg('rating'))['avg']
				review_count = getattr(product, rel).count()
				break
			except Exception:
				pass

	if avg_rating:
		confidence = min(review_count / 10, 1.0)
		val = (float(avg_rating) / 5.0) * 100.0 * confidence * float(profile.quality_sensitivity or 1.0)
		scores['quality'] = min(val, 100)
	else:
		scores['quality'] = 30

	created_at = getattr(product, 'created_at', None)
	if not created_at:
		created_at = getattr(product, 'created', None)
	if created_at:
		age_days = (timezone.now() - created_at).days
		if age_days <= 1:
			scores['recency'] = 100
		elif age_days <= 7:
			scores['recency'] = 80
		elif age_days <= 30:
			scores['recency'] = 50
		else:
			scores['recency'] = max(20, 50 - age_days)
	else:
		scores['recency'] = 50

	scores['popularity'] = min((float(popularity_count) / float(max(1, max_popularity))) * 100.0, 100.0)

	seller = getattr(product, 'store', None)
	seller_trust = 40
	if seller is not None:
		seller_avg = None
		seller_count = 0
		for rel in ['store_reviews', 'reviews']:
			if hasattr(seller, rel):
				try:
					seller_avg = getattr(seller, rel).aggregate(avg=Avg('rating'))['avg']
					seller_count = getattr(seller, rel).count()
					break
				except Exception:
					pass
		# Compute seller trust after the loop (was incorrectly inside it)
		if seller_avg:
			confidence = min(seller_count / 5, 1.0)
			seller_trust = (float(seller_avg) / 5.0) * 100.0 * confidence

		preferred = profile.preferred_sellers or []
		if getattr(seller, 'id', None) in preferred:
			seller_trust = min(seller_trust * 1.3, 100)

	scores['seller_trust'] = seller_trust
	preferred = profile.preferred_sellers or []
	scores['seller_affinity'] = 100 if getattr(seller, 'id', None) in preferred else 25

	# Session intent: short-term boost for recent clicks/favorites.
	session_intent = 0
	session_cats = session_context.get('categories') or set()
	session_sellers = session_context.get('sellers') or set()
	session_products = session_context.get('products') or set()
	if getattr(product, 'id', None) in session_products:
		session_intent += 45
	if getattr(product, 'category_id', None) in session_cats:
		session_intent += 60
	if getattr(product, 'store_id', None) in session_sellers:
		session_intent += 40
	scores['session_intent'] = min(session_intent, 100)

	# Location preference: combine preferred wilayas + preferred max distance.
	location_pref = 0.0
	if preferred_wilayas:
		store = getattr(product, 'store', None)
		address = ''
		if store is not None:
			address = (getattr(store, 'address', '') or getattr(store, 'city', '') or '').lower()
		for w in preferred_wilayas:
			if w and str(w).lower() in address:
				location_pref = 80
				break

	location_pref = max(
		location_pref,
		_distance_preference_score(profile=profile, user=user, store=getattr(product, 'store', None)),
	)
	scores['location_pref'] = location_pref

	# Query-aware keyword match from profile/search history.
	keyword_score = 0
	all_keywords = list(keywords)
	session_queries = session_context.get('queries') or []
	all_keywords.extend(session_queries)
	if all_keywords:
		name = (getattr(product, 'name', '') or '').lower()
		desc = (getattr(product, 'description', '') or '').lower()
		hits = 0
		for kw in all_keywords[:16]:
			if kw and (kw in name or kw in desc):
				hits += 1
		if hits > 0:
			keyword_score = min(100, hits * 40)
	scores['keyword_match'] = keyword_score

	# If user already engaged heavily with this product, avoid repeating it at top.
	if max_user_engagement > 0:
		engagement_ratio = float(user_engagement) / float(max_user_engagement)
		scores['personal_engagement'] = max(0, 100 - (engagement_ratio * 100))
	else:
		scores['personal_engagement'] = 80

	created_at = getattr(product, 'created_at', None) or getattr(product, 'created', None)
	if created_at:
		age_hours = max(0.0, (timezone.now() - created_at).total_seconds() / 3600.0)
		# Exploration novelty: high in first 48h then fades.
		scores['novelty'] = max(0.0, min(100.0, 100.0 - (age_hours / 48.0) * 100.0))
	else:
		scores['novelty'] = 20

	is_negotiable = bool(getattr(product, 'negotiable', False))
	scores['negotiable'] = 100 if is_negotiable else 30

	promotion_score = 0
	ad_boost = 0
	if hasattr(product, 'promotions'):
		try:
			active = product.promotions.filter(
				is_active=True,
				start_date__lte=timezone.now(),
				end_date__gte=timezone.now(),
			).filter(
				Q(max_impressions__isnull=True)
				| Q(unique_viewers_count__lt=models.F('max_impressions'))
			)
			if active.exists():
				best = max(float(p.percentage) for p in active)
				promotion_score = min(best * 2, 100)
			ad_promos = active.filter(kind='advertising')
			if ad_promos.exists():
				best_boost = 0
				for promo in ad_promos:
					val = int(getattr(promo, 'priority_boost', 0) or 0)
					if val > best_boost:
						best_boost = val
				ad_boost = min(100, 40 + (best_boost * 3))
		except Exception:
			promotion_score = 0
	scores['promotion'] = promotion_score
	scores['ad_boost'] = ad_boost

	return scores


def _ranges_adjacent(range1, range2):
	order = ['very_low', 'low', 'medium', 'high', 'very_high']
	try:
		idx1 = order.index(range1)
		idx2 = order.index(range2)
		return abs(idx1 - idx2) <= 1
	except ValueError:
		return False


def _get_match_reasons(breakdown):
	reasons = []
	if breakdown.get('category', 0) >= 70:
		reasons.append('Matches your interests')
	if breakdown.get('price', 0) >= 80:
		reasons.append('Fits your budget')
	if breakdown.get('quality', 0) >= 70:
		reasons.append('Highly rated')
	if breakdown.get('negotiable', 0) >= 100:
		reasons.append('Price negotiable')
	if breakdown.get('promotion', 0) >= 50:
		reasons.append('On sale!')
	if breakdown.get('ad_boost', 0) >= 60:
		reasons.append('Sponsored offer')
	if breakdown.get('recency', 0) >= 80:
		reasons.append('Just listed')
	if breakdown.get('seller_trust', 0) >= 80:
		reasons.append('Trusted seller')
	if breakdown.get('seller_affinity', 0) >= 80:
		reasons.append('From stores you like')
	if breakdown.get('session_intent', 0) >= 60:
		reasons.append('Based on recent activity')
	if breakdown.get('location_pref', 0) >= 80:
		reasons.append('Popular in your area')
	if breakdown.get('keyword_match', 0) >= 80:
		reasons.append('Matches your recent searches')
	if breakdown.get('novelty', 0) >= 70:
		reasons.append('Fresh recommendation')
	return reasons


def _diversify_results(scored_products, max_per_seller=4, max_per_category=4):
	seller_counts = defaultdict(int)
	category_counts = defaultdict(int)
	diversified = []
	for sp in scored_products:
		seller_id = getattr(sp['product'], 'store_id', None)
		category_id = getattr(sp['product'], 'category_id', None)
		if category_id is not None and category_counts[category_id] >= max_per_category:
			continue
		if seller_id is None:
			diversified.append(sp)
			continue
		if seller_counts[seller_id] < max_per_seller:
			diversified.append(sp)
			seller_counts[seller_id] += 1
			if category_id is not None:
				category_counts[category_id] += 1
	return diversified


def _apply_smart_exploration(scored_products, user, limit):
	"""
	Add controlled randomness (exploration) so results don't look identical each time.
	High-quality items still dominate, but newer/less-exposed items get a fair chance.
	"""
	if len(scored_products) <= 4:
		return scored_products

	base_rate = float(getattr(settings, 'RECOMMENDATION_EXPLORATION_RATE', 0.08))
	recent_strong = InteractionLog.objects.filter(
		user=user,
		action__in=['view', 'favorite', 'rate', 'contact', 'negotiate'],
		timestamp__gte=timezone.now() - timedelta(days=30),
	).count()
	# New/low-history users need more exploration.
	dynamic_rate = min(0.15, base_rate + (0.05 if recent_strong < 20 else 0.0))

	top_anchor = scored_products[:2]
	window_size = min(len(scored_products), max(18, int(limit) * 3))
	pool = scored_products[2:window_size]
	rest = scored_products[window_size:]

	for item in pool:
		novelty = float(item.get('breakdown', {}).get('novelty', 0.0))
		promotion = float(item.get('breakdown', {}).get('promotion', 0.0))
		quality = float(item.get('breakdown', {}).get('quality', 0.0))
		base = float(item.get('score', 0.0))

		# Keep quality dominant and add limited exploration jitter.
		jitter = random.uniform(-1.0, 1.0) * dynamic_rate * max(4.0, base * 0.09)
		exploration_bonus = (novelty * 0.02) + (promotion * 0.01) + (quality * 0.005)
		item['_explore_score'] = base + jitter + exploration_bonus

	pool.sort(key=lambda x: x.get('_explore_score', x.get('score', 0.0)), reverse=True)
	for item in pool:
		item.pop('_explore_score', None)
	return top_anchor + pool + rest


def _get_popular_products(limit=20, preferred_wilayas=None, user=None):
	from catalog.models import Product
	preferred_wilayas = preferred_wilayas or []

	popular_ids = InteractionLog.objects.filter(
		timestamp__gte=timezone.now() - timezone.timedelta(days=7),
		product__isnull=False,
	).values('product_id').annotate(count=models.Count('id')).order_by('-count').values_list('product_id', flat=True)[:limit]

	qs = Product.objects.all().select_related('store', 'category')
	if hasattr(Product, 'AVAILABLE') and hasattr(Product, 'available_status'):
		qs = qs.filter(available_status=Product.AVAILABLE)

	if not popular_ids:
		products = qs.order_by('-id')[:limit]
		return [{'product': p, 'score': 0, 'breakdown': {}, 'match_reasons': ['New listing']} for p in products]

	products_by_id = {}

	trending_global = list(qs.filter(id__in=list(popular_ids))[: max(limit * 2, 20)])
	for p in trending_global:
		products_by_id[p.id] = {
			'product': p,
			'score': 55,
			'breakdown': {},
			'match_reasons': ['Trending this week'],
		}

	if preferred_wilayas:
		pref = [str(w).strip().lower() for w in preferred_wilayas if str(w).strip()]
		if pref:
			regional_q = Q()
			for token in pref:
				regional_q |= Q(store__address__icontains=token) | Q(store__city__icontains=token)
			regional_ids = (
				InteractionLog.objects.filter(
					timestamp__gte=timezone.now() - timezone.timedelta(days=7),
					product__isnull=False,
					product__store__isnull=False,
				)
				.filter(regional_q)
				.values('product_id')
				.annotate(count=models.Count('id'))
				.order_by('-count')
				.values_list('product_id', flat=True)[: max(limit * 2, 20)]
			)
			regional_products = list(qs.filter(id__in=list(regional_ids))[: max(limit * 2, 20)])
			for p in regional_products:
				products_by_id[p.id] = {
					'product': p,
					'score': 60,
					'breakdown': {},
					'match_reasons': ['Trending in your region'],
				}

	# New items budget for cold-start exploration.
	new_items = list(qs.order_by('-created_at')[: max(limit * 2, 20)])
	for p in new_items:
		products_by_id.setdefault(
			p.id,
			{
				'product': p,
				'score': 45,
				'breakdown': {},
				'match_reasons': ['New listing'],
			},
		)

	# Keep user-owned products out from fallback recommendations.
	if getattr(user, 'id', None):
		products_by_id = {
			pid: item
			for pid, item in products_by_id.items()
			if getattr(item.get('product'), 'store_id', None) != user.id
		}

	blended = list(products_by_id.values())
	blended.sort(key=lambda x: (x.get('score', 0), getattr(x.get('product'), 'created_at', timezone.now())), reverse=True)
	return blended[:limit]


def _get_user_wilayas(user):
	try:
		address = (getattr(user, 'address', '') or getattr(user, 'location', '') or '').lower()
		if not address:
			return []
		parts = [p.strip() for p in address.split(',') if p.strip()]
		return parts[-1:] if parts else []
	except Exception:
		return []


def _get_session_context(user):
	# Session intent from last N interactions, prioritizing recent clicks/favorites.
	window = int(getattr(settings, 'ANALYTICS_SESSION_INTENT_EVENTS', 25))
	recent = InteractionLog.objects.filter(
		user=user,
		action__in=['click', 'favorite', 'view', 'rate', 'contact', 'negotiate'],
		timestamp__gte=timezone.now() - timedelta(days=2),
	).select_related('product')[:window]

	recent_searches = list(
		InteractionLog.objects.filter(
			user=user,
			action='search',
			timestamp__gte=timezone.now() - timedelta(days=2),
		)
		.values_list('metadata', flat=True)[:12]
	)

	categories = set()
	sellers = set()
	products = set()
	queries = []
	for i in recent:
		if i.product_id and i.product:
			products.add(i.product_id)
			if i.product.category_id:
				categories.add(i.product.category_id)
			if getattr(i.product, 'store_id', None):
				sellers.add(i.product.store_id)

	for meta in recent_searches:
		meta = meta or {}
		q = str(meta.get('search_query') or meta.get('keyword') or '').strip().lower()
		if q:
			queries.append(q)

	return {'categories': categories, 'sellers': sellers, 'products': products, 'queries': queries}


def _haversine_km(lat1, lon1, lat2, lon2):
	# Great-circle distance in KM.
	r = 6371.0
	dlat = radians(lat2 - lat1)
	dlon = radians(lon2 - lon1)
	a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
	c = 2 * asin(sqrt(a))
	return r * c


def _distance_preference_score(profile, user, store):
	if profile is None or user is None or store is None:
		return 0.0

	try:
		user_lat = float(getattr(user, 'latitude', None))
		user_lon = float(getattr(user, 'longitude', None))
		store_lat = float(getattr(store, 'latitude', None))
		store_lon = float(getattr(store, 'longitude', None))
	except Exception:
		return 0.0

	max_km = float(getattr(profile, 'preferred_max_distance_km', 0.0) or 0.0)
	if max_km <= 0:
		return 0.0

	distance_km = _haversine_km(user_lat, user_lon, store_lat, store_lon)
	if distance_km <= max_km:
		return 100.0
	if distance_km <= max_km * 2:
		return 60.0
	if distance_km <= max_km * 3:
		return 25.0
	return 0.0


def get_recommended_stores(user, limit=8):
	"""
	Get recommended stores based on user's interaction history and comprehensive scoring.
	Does NOT filter stores without posts - shows ALL stores.
	"""
	import random
	import math
	from django.utils import timezone
	from users.models import User
	
	# Get user's category preferences from interactions
	preferred_categories = []
	if user and user.is_authenticated:
		try:
			profile = UserInterestProfile.objects.get(user=user)
			preferred_categories = profile.get_top_categories(limit=5)
		except UserInterestProfile.DoesNotExist:
			# Fallback: get from recent interactions
			recent_cats = InteractionLog.objects.filter(
				user=user,
				category__isnull=False,
				timestamp__gte=timezone.now() - timezone.timedelta(days=30)
			).values_list('category_id', flat=True).distinct()[:5]
			preferred_categories = list(recent_cats)
	
	# Get ALL stores with annotations - NO posts_count filter
	stores = User.objects.annotate(
		avg_rating=models.Avg('store_reviews__rating'),
		review_count=models.Count('store_reviews', distinct=True),
		posts_count=models.Count('posts', distinct=True),
		followers_count_ann=models.Count('following', distinct=True),
	)
	
	scored_stores = []
	now = timezone.now()
	
	for store in stores:
		score = 0.0
		
		# Multi-factor scoring (same as backend)
		avg_rating = store.avg_rating or 0
		review_count = store.review_count or 0
		posts_count = store.posts_count or 0
		followers = store.followers_count_ann or 0
		
		# Rating with confidence
		rating_confidence = min(review_count / 10.0, 1.0)
		score += (avg_rating / 5.0) * 25.0 * rating_confidence
		
		# Logarithmic scaling for counts
		if review_count > 0:
			score += min(math.log(review_count + 1) * 3, 15)
		if posts_count > 0:
			score += min(math.log(posts_count + 1) * 4, 20)
		if followers > 0:
			score += min(math.log(followers + 1) * 2, 10)
		
		# Account age
		age_days = (now - store.date_joined).days
		score += min(age_days / 365.0 * 10, 10)
		
		# Category matching
		if preferred_categories:
			store_cats = set(store.posts.values_list('category_id', flat=True).distinct())
			matches = len(set(preferred_categories) & store_cats)
			if matches > 0:
				score += min(matches * 5, 20)
		
		# Random jitter for variety
		score += random.uniform(0, 5)
		
		scored_stores.append((score, store))
	
	# Sort and randomize
	random.shuffle(scored_stores)
	scored_stores.sort(key=lambda x: x[0], reverse=True)
	
	return [store for _, store in scored_stores[:limit]]
