from django.db import models


class AdCampaign(models.Model):
	PLACEMENT_HOME_TOP = 'home_top'
	PLACEMENT_HOME_FEED = 'home_feed'
	PLACEMENT_SEARCH_TOP = 'search_top'
	PLACEMENT_CHOICES = (
		(PLACEMENT_HOME_TOP, 'Home Top'),
		(PLACEMENT_HOME_FEED, 'Home Feed'),
		(PLACEMENT_SEARCH_TOP, 'Search Top'),
	)

	AUDIENCE_ALL = 'all'
	AUDIENCE_FOLLOWERS = 'followers'
	AUDIENCE_NEARBY = 'nearby'
	AUDIENCE_WILAYA = 'wilaya'
	AUDIENCE_CHOICES = (
		(AUDIENCE_ALL, 'All'),
		(AUDIENCE_FOLLOWERS, 'Followers'),
		(AUDIENCE_NEARBY, 'Nearby'),
		(AUDIENCE_WILAYA, 'Wilaya'),
	)

	GEO_MODE_ALL = 'all'
	GEO_MODE_WILAYA = 'wilaya'
	GEO_MODE_RADIUS = 'radius'
	GEO_MODE_CHOICES = (
		(GEO_MODE_ALL, 'All Algeria'),
		(GEO_MODE_WILAYA, 'Specific Wilayas'),
		(GEO_MODE_RADIUS, 'Radius (km)'),
	)

	store = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='ad_campaigns')
	product = models.ForeignKey('catalog.Product', on_delete=models.SET_NULL, blank=True, null=True, related_name='ad_campaigns')
	pack = models.ForeignKey('catalog.Pack', on_delete=models.SET_NULL, blank=True, null=True, related_name='ad_campaigns')
	name = models.CharField(max_length=255)
	description = models.TextField(blank=True)
	percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0.0)
	placement = models.CharField(max_length=20, choices=PLACEMENT_CHOICES, default=PLACEMENT_HOME_TOP)
	audience_mode = models.CharField(max_length=20, choices=AUDIENCE_CHOICES, default=AUDIENCE_ALL)
	age_from = models.PositiveIntegerField(null=True, blank=True)
	age_to = models.PositiveIntegerField(null=True, blank=True)
	geo_mode = models.CharField(max_length=10, choices=GEO_MODE_CHOICES, default=GEO_MODE_ALL)
	target_wilayas = models.JSONField(default=list, blank=True)
	target_radius_km = models.PositiveIntegerField(null=True, blank=True)
	target_categories = models.JSONField(default=list, blank=True)
	is_active = models.BooleanField(default=True)
	start_date = models.DateTimeField(null=True, blank=True)
	end_date = models.DateTimeField(null=True, blank=True)
	max_impressions = models.PositiveIntegerField(null=True, blank=True)
	unique_viewers_count = models.PositiveIntegerField(default=0)
	impressions_count = models.PositiveIntegerField(default=0)
	clicks_count = models.PositiveIntegerField(default=0)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']

	def __str__(self) -> str:
		return self.name

	def clean(self):
		has_product = self.product_id is not None
		has_pack = self.pack_id is not None
		if has_product == has_pack:
			from django.core.exceptions import ValidationError
			raise ValidationError('Ad campaign must target exactly one of product or pack.')


class AdCampaignViewer(models.Model):
	campaign = models.ForeignKey(AdCampaign, on_delete=models.CASCADE, related_name='viewer_hits')
	viewer_key = models.CharField(max_length=128, db_index=True)
	first_seen_at = models.DateTimeField(auto_now_add=True)
	last_seen_at = models.DateTimeField(auto_now=True)

	class Meta:
		unique_together = ('campaign', 'viewer_key')
