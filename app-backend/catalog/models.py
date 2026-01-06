from django.conf import settings
from django.db import models
from stores.models import Store


class Category(models.Model):
	name = models.CharField(max_length=255)
	parent = models.ForeignKey('self', on_delete=models.SET_NULL, blank=True, null=True, related_name='subcategories')

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return self.name


class Product(models.Model):
	AVAILABLE = 'available'
	OUT_OF_STOCK = 'out_of_stock'
	STATUS_CHOICES = ((AVAILABLE, 'Available'), (OUT_OF_STOCK, 'Out of Stock'))

	store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='products')
	category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='products')
	name = models.CharField(max_length=255)
	description = models.TextField(blank=True)
	price = models.DecimalField(max_digits=10, decimal_places=2)
	negotiable = models.BooleanField(default=False)
	available_status = models.CharField(max_length=15, choices=STATUS_CHOICES, default=AVAILABLE)
	created_at = models.DateTimeField(auto_now_add=True)

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return self.name


class ProductImage(models.Model):
	product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='images')
	image = models.ImageField(upload_to='products/')
	is_main = models.BooleanField(default=False)

	class Meta:
		ordering = ['-is_main']


class Pack(models.Model):
	store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='packs')
	name = models.CharField(max_length=255)
	description = models.TextField(blank=True)
	discount = models.DecimalField(max_digits=5, decimal_places=2, default=0.0)
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
	user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reviews')
	store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='reviews', null=True, blank=True)
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
