from django.db import models
from catalog.models import Product
from stores.models import Store


class Promotion(models.Model):
	store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='promotions')
	product = models.ForeignKey(Product, on_delete=models.SET_NULL, blank=True, null=True, related_name='promotions')
	name = models.CharField(max_length=255)
	description = models.TextField(blank=True)
	percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0.0)
	start_date = models.DateTimeField()
	end_date = models.DateTimeField()

	def __str__(self) -> str:  # pragma: no cover - simple repr
		return self.name


class PromotionImage(models.Model):
	promotion = models.ForeignKey(Promotion, on_delete=models.CASCADE, related_name='images')
	image = models.ImageField(upload_to='promotions/')
	is_main = models.BooleanField(default=False)

	class Meta:
		ordering = ['-is_main']

# Create your models here.
