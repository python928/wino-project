from rest_framework import serializers

from analytics.models import InteractionLog
from catalog.models import Category, Product
from users.models import User


class InteractionEventSerializer(serializers.Serializer):
	action = serializers.ChoiceField(choices=[a[0] for a in InteractionLog.ACTION_CHOICES])
	product = serializers.PrimaryKeyRelatedField(
		queryset=Product.objects.all(),
		required=False,
		allow_null=True,
	)
	store = serializers.PrimaryKeyRelatedField(
		queryset=User.objects.all(),
		required=False,
		allow_null=True,
	)
	category = serializers.PrimaryKeyRelatedField(
		queryset=Category.objects.all(),
		required=False,
		allow_null=True,
	)
	session_id = serializers.CharField(required=False, allow_blank=True, max_length=100)
	metadata = serializers.JSONField(required=False)

	def validate(self, attrs):
		action = attrs.get('action')
		product = attrs.get('product')
		store = attrs.get('store')
		category = attrs.get('category')

		if action in {'view', 'click', 'promotion_click', 'favorite', 'compare', 'contact', 'negotiate', 'share', 'rate'} and product is None:
			raise serializers.ValidationError({'product': 'This action requires product'})
		if action == 'follow_store' and store is None:
			raise serializers.ValidationError({'store': 'This action requires store'})
		if product is not None and category is None and getattr(product, 'category_id', None):
			attrs['category'] = product.category
		return attrs


class RecommendationItemSerializer(serializers.Serializer):
	"""
	Serializes a single recommendation result dict:
	  {
	    'product': <Product instance>,
	    'score':   float,
	    'match_reasons': [str, ...],
	  }

	The 'product' nested object includes enough data for the Flutter card
	to render without an extra API call.
	"""
	product = serializers.SerializerMethodField()
	score = serializers.FloatField()
	match_reasons = serializers.ListField(child=serializers.CharField(), required=False)

	def get_product(self, obj):
		product = obj.get('product')
		if not product:
			return None

		# Main image URL (prefetched in recommendations.py)
		image_url = None
		if hasattr(product, 'images'):
			try:
				main_img = product.images.filter(is_main=True).first()
				if not main_img:
					main_img = product.images.first()
				if main_img and main_img.image:
					request = self.context.get('request')
					image_url = (
						request.build_absolute_uri(main_img.image.url)
						if request
						else main_img.image.url
					)
			except Exception:
				pass

		# Store display name (select_related in recommendations.py)
		store = getattr(product, 'store', None)
		store_name = ''
		if store:
			store_name = getattr(store, 'name', '') or getattr(store, 'username', '')

		price = getattr(product, 'price', None)

		return {
			'id': product.id,
			'name': getattr(product, 'name', ''),
			'price': str(price) if price is not None else None,
			'hide_price': getattr(product, 'hide_price', False),
			'negotiable': getattr(product, 'negotiable', False),
			'category_id': getattr(product, 'category_id', None),
			'store_id': getattr(product, 'store_id', None),
			'store_name': store_name,
			'image_url': image_url,
		}
