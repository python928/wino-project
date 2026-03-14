from django.conf import settings
from django.db import models


class Category(models.Model):
	name = models.CharField(max_length=255)
	parent = models.ForeignKey('self', on_delete=models.SET_NULL, blank=True, null=True, related_name='subcategories')
	# Material Icons fields — served to Flutter as a JSON object
	icon_code_point = models.CharField(max_length=10, blank=True, default='', help_text='Hex codePoint from fonts.google.com/icons, e.g. e027, e532')
	icon_font_family = models.CharField(max_length=100, default='MaterialIcons', blank=True)
	icon_font_package = models.CharField(max_length=100, blank=True, default='')
	
	# Adaptive Search: 1=Abundant (low radius), 10=Scarce (high radius)
	scarcity_level = models.IntegerField(default=5, help_text="1=Abundant (Bread), 10=Scarce (Cars)")

	def __str__(self) -> str:
		return self.name


class Product(models.Model):
	AVAILABLE = 'available'
	OUT_OF_STOCK = 'out_of_stock'
	STATUS_CHOICES = ((AVAILABLE, 'Available'), (OUT_OF_STOCK, 'Out of Stock'))

	store = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='products')
	category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='products')
	name = models.CharField(max_length=255)
	description = models.TextField(blank=True)
	price = models.DecimalField(max_digits=10, decimal_places=2)
	hide_price = models.BooleanField(default=False)
	negotiable = models.BooleanField(default=False)
	available_status = models.CharField(max_length=15, choices=STATUS_CHOICES, default=AVAILABLE)
	delivery_available = models.BooleanField(default=False)
	delivery_wilayas = models.TextField(blank=True, default='')  # comma-separated; empty = use store.address
	created_at = models.DateTimeField(auto_now_add=True)

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return self.name


class ProductImage(models.Model):
	product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='images')
	image = models.ImageField(upload_to='products/')
	is_main = models.BooleanField(default=False)

	class Meta:
		ordering = ['-is_main']


class Promotion(models.Model):
	KIND_PROMOTION = 'promotion'
	KIND_ADVERTISING = 'advertising'
	KIND_CHOICES = (
		(KIND_PROMOTION, 'Promotion'),
		(KIND_ADVERTISING, 'Advertising'),
	)

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
	AUDIENCE_CUSTOM = 'custom'
	AUDIENCE_CHOICES = (
		(AUDIENCE_ALL, 'All'),
		(AUDIENCE_FOLLOWERS, 'Followers'),
		(AUDIENCE_NEARBY, 'Nearby'),
		(AUDIENCE_WILAYA, 'Wilaya'),
		(AUDIENCE_CUSTOM, 'Custom Users'),
	)

	# Unified: store == users.User
	store = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='promotions')
	product = models.ForeignKey(Product, on_delete=models.SET_NULL, blank=True, null=True, related_name='promotions')
	name = models.CharField(max_length=255)
	description = models.TextField(blank=True)
	percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0.0)
	kind = models.CharField(max_length=20, choices=KIND_CHOICES, default=KIND_PROMOTION)
	placement = models.CharField(max_length=20, choices=PLACEMENT_CHOICES, default=PLACEMENT_HOME_TOP)
	audience_mode = models.CharField(max_length=20, choices=AUDIENCE_CHOICES, default=AUDIENCE_ALL)
	target_wilayas = models.JSONField(default=list, blank=True)
	target_categories = models.JSONField(default=list, blank=True)
	target_user_ids = models.JSONField(default=list, blank=True)
	priority_boost = models.IntegerField(default=0)
	is_active = models.BooleanField(default=True)
	start_date = models.DateTimeField()
	end_date = models.DateTimeField()
	max_impressions = models.PositiveIntegerField(
		null=True,
		blank=True,
		help_text='Maximum unique viewers allowed for this promotion (null = unlimited).',
	)
	unique_viewers_count = models.PositiveIntegerField(default=0)
	impressions_count = models.PositiveIntegerField(default=0)
	clicks_count = models.PositiveIntegerField(default=0)
	created_at = models.DateTimeField(auto_now_add=True)

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return self.name


class PromotionViewer(models.Model):
	promotion = models.ForeignKey(Promotion, on_delete=models.CASCADE, related_name='viewer_hits')
	viewer_key = models.CharField(max_length=128, db_index=True)
	first_seen_at = models.DateTimeField(auto_now_add=True)
	last_seen_at = models.DateTimeField(auto_now=True)

	class Meta:
		unique_together = ('promotion', 'viewer_key')


class PromotionImage(models.Model):
	promotion = models.ForeignKey(Promotion, on_delete=models.CASCADE, related_name='images')
	image = models.ImageField(upload_to='promotions/')
	is_main = models.BooleanField(default=False)

	class Meta:
		ordering = ['-is_main']


class Pack(models.Model):
	AVAILABLE = 'available'
	OUT_OF_STOCK = 'out_of_stock'
	STATUS_CHOICES = ((AVAILABLE, 'Available'), (OUT_OF_STOCK, 'Out of Stock'))

	merchant = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='packs')
	name = models.CharField(max_length=255)
	description = models.TextField(blank=True)
	discount = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
	available_status = models.CharField(max_length=15, choices=STATUS_CHOICES, default=AVAILABLE)
	delivery_available = models.BooleanField(default=False)
	delivery_wilayas = models.TextField(blank=True, default='')  # comma-separated; empty = use store.address
	created_at = models.DateTimeField(auto_now_add=True)

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return self.name


class PackProduct(models.Model):
	pack = models.ForeignKey(Pack, on_delete=models.CASCADE, related_name='pack_products')
	product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='in_packs')
	quantity = models.PositiveIntegerField(default=1)

	class Meta:
		unique_together = ('pack', 'product')


class PackImage(models.Model):
	pack = models.ForeignKey(Pack, on_delete=models.CASCADE, related_name='images')
	image = models.ImageField(upload_to='packs/')
	is_main = models.BooleanField(default=False)

	class Meta:
		ordering = ['-is_main']


class Review(models.Model):
	user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='user_reviews')
	store = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='store_reviews', null=True, blank=True)
	product = models.ForeignKey(Product, on_delete=models.SET_NULL, blank=True, null=True, related_name='reviews')
	rating = models.IntegerField()
	comment = models.TextField(blank=True)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']
		# Allow one review per user per product OR per store (when product is null)
		constraints = [
			models.UniqueConstraint(
				fields=['user', 'product'],
				condition=models.Q(product__isnull=False),
				name='unique_user_product_review'
			),
			models.UniqueConstraint(
				fields=['user', 'store'],
				condition=models.Q(product__isnull=True),
				name='unique_user_store_review'
			),
		]


class Favorite(models.Model):
	user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='favorites')
	product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='favorited_by')
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']
		unique_together = ['user', 'product']  # One favorite per user per product

	def __str__(self):
		return f"{self.user.username} - {self.product.name}"


class ProductReport(models.Model):
	REASON_SPAM = 'spam'
	REASON_FAKE = 'fake'
	REASON_FRAUD = 'fraud'
	REASON_OFFENSIVE = 'offensive'
	REASON_OTHER = 'other'

	REASON_CHOICES = (
		(REASON_SPAM, 'Spam'),
		(REASON_FAKE, 'Fake Product'),
		(REASON_FRAUD, 'Fraud / Scam'),
		(REASON_OFFENSIVE, 'Offensive Content'),
		(REASON_OTHER, 'Other'),
	)

	STATUS_PENDING = 'pending'
	STATUS_REVIEWED = 'reviewed'
	STATUS_REJECTED = 'rejected'
	STATUS_CHOICES = (
		(STATUS_PENDING, 'Pending'),
		(STATUS_REVIEWED, 'Reviewed'),
		(STATUS_REJECTED, 'Rejected'),
	)

	reporter = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		on_delete=models.CASCADE,
		related_name='product_reports_sent',
	)
	product = models.ForeignKey(
		Product,
		on_delete=models.CASCADE,
		related_name='reports_received',
	)
	reason = models.CharField(max_length=20, choices=REASON_CHOICES)
	details = models.TextField(blank=True, default='')
	status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']
		unique_together = ('reporter', 'product')

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return f"{self.reporter_id} -> product:{self.product_id} ({self.reason})"
