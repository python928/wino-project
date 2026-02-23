import logging
from collections import defaultdict

from django.db import models
from django.db.models import Avg, Q
from django.utils import timezone

from analytics.models import InteractionLog, UserInterestProfile
from analytics.utils import get_price_range

logger = logging.getLogger(__name__)


SCORE_WEIGHTS = {
	'category': 0.30,
	'price': 0.15,
	'quality': 0.15,
	'recency': 0.10,
	'popularity': 0.10,
	'seller_trust': 0.10,
	'negotiable': 0.05,
	'promotion': 0.05,
}


def get_recommended_products(user, limit=20, category_filter=None):
	from catalog.models import Product

	try:
		profile = UserInterestProfile.objects.get(user=user)
	except UserInterestProfile.DoesNotExist:
		return _get_popular_products(limit)

	top_categories = profile.get_top_categories(limit=7)
	if not top_categories:
		return _get_popular_products(limit)

	qs = Product.objects.filter().select_related('store', 'category').prefetch_related('images', 'reviews', 'promotions')

	# Best-effort: handle AVAILABLE constant if present, else just return all.
	if hasattr(Product, 'AVAILABLE') and hasattr(Product, 'available_status'):
		qs = qs.filter(available_status=Product.AVAILABLE)

	if category_filter:
		qs = qs.filter(category_id=category_filter)
	else:
		qs = qs.filter(Q(category_id__in=top_categories) | Q(category__parent_id__in=top_categories))

	candidates = list(qs[:150])
	if not candidates:
		return _get_popular_products(limit)

	scored = []
	for product in candidates:
		breakdown = _calculate_product_score(product, profile)
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
			timestamp__gte=timezone.now() - timezone.timedelta(hours=6),
		).values_list('product_id', flat=True)
	)

	scored = [sp for sp in scored if sp['product'].id not in recently_viewed]
	scored.sort(key=lambda x: x['score'], reverse=True)
	return _diversify_results(scored, max_per_seller=4)[:limit]


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


def _calculate_product_score(product, profile):
	scores = {}

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

	interaction_count = InteractionLog.objects.filter(
		product=product,
		timestamp__gte=timezone.now() - timezone.timedelta(days=7),
	).count()
	scores['popularity'] = min(interaction_count * 5, 100)

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
	is_negotiable = bool(getattr(product, 'negotiable', False))
	scores['negotiable'] = 100 if is_negotiable else 30

	promotion_score = 0
	if hasattr(product, 'promotions'):
		try:
			active = product.promotions.filter(
				is_active=True,
				start_date__lte=timezone.now(),
				end_date__gte=timezone.now(),
			)
			if active.exists():
				best = max(float(p.percentage) for p in active)
				promotion_score = min(best * 2, 100)
		except Exception:
			promotion_score = 0
	scores['promotion'] = promotion_score

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
	if breakdown.get('recency', 0) >= 80:
		reasons.append('Just listed')
	if breakdown.get('seller_trust', 0) >= 80:
		reasons.append('Trusted seller')
	return reasons


def _diversify_results(scored_products, max_per_seller=4):
	seller_counts = defaultdict(int)
	diversified = []
	for sp in scored_products:
		seller_id = getattr(sp['product'], 'store_id', None)
		if seller_id is None:
			diversified.append(sp)
			continue
		if seller_counts[seller_id] < max_per_seller:
			diversified.append(sp)
			seller_counts[seller_id] += 1
	return diversified


def _get_popular_products(limit=20):
	from catalog.models import Product

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

	products = qs.filter(id__in=list(popular_ids))
	return [{'product': p, 'score': 50, 'breakdown': {}, 'match_reasons': ['Trending this week']} for p in products]


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
