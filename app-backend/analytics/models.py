from django.conf import settings
from django.db import models


class UserInterestProfile(models.Model):
	"""Computed user preferences, periodically updated from raw interaction logs."""

	user = models.OneToOneField(
		settings.AUTH_USER_MODEL,
		on_delete=models.CASCADE,
		related_name='interest_profile',
	)

	category_scores = models.JSONField(default=dict, blank=True)
	price_affinity = models.JSONField(default=dict, blank=True)

	distance_sensitivity = models.FloatField(default=1.0)
	quality_sensitivity = models.FloatField(default=1.0)
	preferred_max_distance_km = models.FloatField(default=50.0)

	preferred_wilayas = models.JSONField(default=list, blank=True)
	search_keywords = models.JSONField(default=dict, blank=True)
	preferred_sellers = models.JSONField(default=list, blank=True)

	last_updated = models.DateTimeField(auto_now=True)

	class Meta:
		verbose_name = 'User Interest Profile'
		verbose_name_plural = 'User Interest Profiles'

	def __str__(self):
		return f"Interest Profile: {self.user}"

	def get_top_categories(self, limit=5):
		if not self.category_scores:
			return []
		sorted_cats = sorted(self.category_scores.items(), key=lambda x: x[1], reverse=True)
		return [int(cat_id) for cat_id, _ in sorted_cats[:limit]]

	def get_price_range_preference(self):
		if not self.price_affinity:
			return 'medium'
		return max(self.price_affinity, key=self.price_affinity.get)


class InteractionLog(models.Model):
	"""Append-only table of user interactions used for analytics/recommendations."""

	ACTION_CHOICES = (
		('view', 'View Product'),
		('click', 'Click Product'),
		('search', 'Search Keyword'),
		('filter_price', 'Filter by Price'),
		('filter_dist', 'Filter by Distance'),
		('filter_wilaya', 'Filter by Wilaya'),
		('filter_rating', 'Filter by Rating'),
		('contact', 'Contact Seller'),
		('favorite', 'Add to Favorites'),
		('negotiate', 'Request Negotiation'),
		('share', 'Share Product'),
		('compare', 'Compare Product'),
	)

	user = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		on_delete=models.CASCADE,
		related_name='interactions',
	)

	product = models.ForeignKey(
		'catalog.Product',
		null=True,
		blank=True,
		on_delete=models.SET_NULL,
		related_name='interactions',
	)

	category = models.ForeignKey(
		'catalog.Category',
		null=True,
		blank=True,
		on_delete=models.SET_NULL,
		related_name='interactions',
	)

	action = models.CharField(max_length=20, choices=ACTION_CHOICES)
	metadata = models.JSONField(default=dict, blank=True)
	session_id = models.CharField(max_length=100, blank=True, default='')
	timestamp = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-timestamp']
		indexes = [
			models.Index(fields=['user', 'action', 'timestamp']),
			models.Index(fields=['user', 'category']),
			models.Index(fields=['timestamp']),
		]
		verbose_name = 'Interaction Log'
		verbose_name_plural = 'Interaction Logs'

	def __str__(self):
		return f"{self.user} - {self.action} - {self.timestamp}"
