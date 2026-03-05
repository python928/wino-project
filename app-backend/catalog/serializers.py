from rest_framework import serializers
from django.db.models import Avg

from .models import Category, Pack, PackImage, PackProduct, Product, ProductImage, Review, Favorite, Promotion, PromotionImage, ProductReport


class CategorySerializer(serializers.ModelSerializer):
    icon = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ['id', 'name', 'parent', 'icon']

    def get_icon(self, obj):
        if not obj.icon_code_point:
            return None
        try:
            import re
            # Clean string: keep only 0-9, a-f, A-F
            clean_hex = re.sub(r'[^0-9a-fA-F]', '', str(obj.icon_code_point))
            if not clean_hex:
                return None
            return {
                'codePoint': int(clean_hex, 16),
                'fontFamily': obj.icon_font_family or 'MaterialIcons',
                'fontPackage': obj.icon_font_package or None,
            }
        except (ValueError, TypeError):
            return None


class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['id', 'product', 'image', 'is_main']
        read_only_fields = ['id']


class StoreMinimalSerializer(serializers.ModelSerializer):
    """Minimal store info embedded in product/pack responses."""
    store_avatar = serializers.SerializerMethodField()
    display_name = serializers.SerializerMethodField()
    store_name = serializers.CharField(source='name', read_only=True)

    class Meta:
        from django.contrib.auth import get_user_model
        model = get_user_model()
        fields = ['id', 'username', 'store_name', 'display_name', 'store_avatar']

    def get_store_avatar(self, obj):
        request = self.context.get('request')
        if obj.profile_image:
            if request:
                return request.build_absolute_uri(obj.profile_image.url)
            return obj.profile_image.url
        return None

    def get_display_name(self, obj):
        # Return name if set, fall back to username — never "local store"
        return obj.name or obj.username


class ProductSerializer(serializers.ModelSerializer):
    store = StoreMinimalSerializer(read_only=True)
    images = ProductImageSerializer(many=True, read_only=True)
    average_rating = serializers.SerializerMethodField()
    review_count = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()
    store_name = serializers.SerializerMethodField()
    store_address = serializers.SerializerMethodField()
    store_latitude = serializers.SerializerMethodField()
    store_longitude = serializers.SerializerMethodField()
    store_nearby_visible = serializers.SerializerMethodField()
    # Effective delivery areas: returns stored wilayas if set, else store.address (dynamic fallback)
    delivery_areas = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            'id',
            'store',
            'category',
            'name',
            'description',
            'price',
            'hide_price',
            'negotiable',
            'available_status',
            'delivery_available',
            'delivery_wilayas',
            'delivery_areas',
            'created_at',
            'images',
            'average_rating',
            'review_count',
            'is_favorited',
            'store_name',
            'store_address',
            'store_latitude',
            'store_longitude',
            'store_nearby_visible',
        ]
        read_only_fields = ['id', 'created_at', 'delivery_areas']

    def get_average_rating(self, obj):
        avg = obj.reviews.aggregate(Avg('rating'))['rating__avg']
        return round(avg, 1) if avg else 0.0

    def get_review_count(self, obj):
        return obj.reviews.count()

    def get_is_favorited(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Favorite.objects.filter(user=request.user, product=obj).exists()
        return False

    def get_store_name(self, obj):
        return getattr(obj.store, 'name', None) or getattr(obj.store, 'username', '')

    def get_store_address(self, obj):
        return getattr(obj.store, 'address', '') or ''

    def get_store_latitude(self, obj):
        lat = getattr(obj.store, 'latitude', None)
        return str(lat) if lat is not None else None

    def get_store_longitude(self, obj):
        lng = getattr(obj.store, 'longitude', None)
        return str(lng) if lng is not None else None

    def get_store_nearby_visible(self, obj):
        return bool(getattr(obj.store, 'allow_nearby_visibility', True))

    def get_delivery_areas(self, obj):
        """Return stored wilayas if set; fall back to store.address dynamically."""
        if obj.delivery_wilayas and obj.delivery_wilayas.strip():
            return obj.delivery_wilayas
        # Dynamic fallback: use the seller's current address
        return getattr(obj.store, 'address', '') or ''


class PackProductSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_image = serializers.SerializerMethodField()
    product_price = serializers.DecimalField(source='product.price', max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = PackProduct
        fields = ['id', 'product', 'product_name', 'product_image', 'product_price', 'quantity']

    def get_product_image(self, obj):
        image = obj.product.images.filter(is_main=True).first() or obj.product.images.first()
        return image.image.url if image else ''


class PackImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PackImage
        fields = ['id', 'pack', 'image', 'is_main']
        read_only_fields = ['id']


class PackSerializer(serializers.ModelSerializer):
    pack_products = PackProductSerializer(many=True, read_only=True)
    images = PackImageSerializer(many=True, read_only=True)
    
    # Input fields matching frontend
    products = serializers.ListField(write_only=True, required=False)
    merchant_id = serializers.IntegerField(read_only=True)
    merchant_name = serializers.CharField(source='merchant.name', read_only=True)
    merchant_latitude = serializers.SerializerMethodField()
    merchant_longitude = serializers.SerializerMethodField()
    merchant_nearby_visible = serializers.SerializerMethodField()
    discount_price = serializers.DecimalField(source='discount', max_digits=10, decimal_places=2)
    total_price = serializers.SerializerMethodField()
    # Effective delivery areas (same dynamic fallback as Product)
    delivery_areas = serializers.SerializerMethodField()

    class Meta:
        model = Pack
        fields = ['id', 'merchant_id', 'merchant_name', 'name', 'description',
                  'merchant_latitude', 'merchant_longitude', 'merchant_nearby_visible',
                  'discount_price', 'total_price', 'available_status',
                  'delivery_available', 'delivery_wilayas', 'delivery_areas',
                  'created_at', 'pack_products', 'images', 'products']
        read_only_fields = ['id', 'created_at', 'pack_products', 'images', 'delivery_areas']

    def get_total_price(self, obj):
        return sum(pp.product.price * pp.quantity for pp in obj.pack_products.all())

    def get_delivery_areas(self, obj):
        """Return stored wilayas if set; fall back to merchant.address dynamically."""
        if obj.delivery_wilayas and obj.delivery_wilayas.strip():
            return obj.delivery_wilayas
        return getattr(obj.merchant, 'address', '') or ''

    def get_merchant_latitude(self, obj):
        lat = getattr(obj.merchant, 'latitude', None)
        return str(lat) if lat is not None else None

    def get_merchant_longitude(self, obj):
        lng = getattr(obj.merchant, 'longitude', None)
        return str(lng) if lng is not None else None

    def get_merchant_nearby_visible(self, obj):
        return bool(getattr(obj.merchant, 'allow_nearby_visibility', True))

    def validate_products(self, value):
        """Ensure packs can only contain the current merchant's own products."""
        request = self.context.get('request')
        if request is None or not getattr(request, 'user', None) or not request.user.is_authenticated:
            raise serializers.ValidationError('Authentication required')

        for item in value or []:
            if not isinstance(item, dict):
                raise serializers.ValidationError('Invalid products payload')
            product_id = item.get('product_id') or item.get('product')
            if not product_id:
                raise serializers.ValidationError('product_id is required')
            if not Product.objects.filter(id=product_id, store=request.user).exists():
                raise serializers.ValidationError('Pack products must belong to the merchant')
        return value

    def create(self, validated_data):
        products_data = validated_data.pop('products', [])
        pack = Pack.objects.create(**validated_data)
        
        for item in products_data:
            product_id = item.get('product_id')
            quantity = item.get('quantity', 1)
            if product_id:
                PackProduct.objects.create(pack=pack, product_id=product_id, quantity=quantity)
        
        return pack

    def update(self, instance, validated_data):
        products_data = validated_data.pop('products', None)
        instance = super().update(instance, validated_data)

        # If products are provided, replace pack contents.
        if products_data is not None:
            instance.pack_products.all().delete()
            for item in products_data:
                product_id = item.get('product_id') or item.get('product')
                quantity = item.get('quantity', 1)
                if product_id:
                    PackProduct.objects.create(
                        pack=instance,
                        product_id=product_id,
                        quantity=quantity,
                    )

        return instance


class ReviewSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.id')
    user_name = serializers.SerializerMethodField()
    username = serializers.ReadOnlyField(source='user.username')
    store_name = serializers.CharField(source='store.name', read_only=True)

    class Meta:
        model = Review
        fields = ['id', 'user', 'user_name', 'username', 'store', 'product', 'rating', 'comment', 'created_at', 'store_name']
        read_only_fields = ['id', 'user', 'user_name', 'username', 'store', 'product', 'created_at']

    def get_user_name(self, obj):
        return obj.user.name if hasattr(obj.user, 'name') and obj.user.name else obj.user.username


class FavoriteSerializer(serializers.ModelSerializer):
    product_detail = ProductSerializer(source='product', read_only=True)

    class Meta:
        model = Favorite
        fields = ['id', 'user', 'product', 'product_detail', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class PromotionImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PromotionImage
        fields = ['id', 'promotion', 'image', 'is_main']
        read_only_fields = ['id']


class PromotionSerializer(serializers.ModelSerializer):
    images = PromotionImageSerializer(many=True, read_only=True)
    store = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Promotion
        fields = [
            'id',
            'store',
            'product',
            'name',
            'description',
            'percentage',
            'is_active',
            'start_date',
            'end_date',
            'created_at',
            'images',
        ]
        read_only_fields = ['id', 'created_at']


class ProductReportSerializer(serializers.ModelSerializer):
    reporter = serializers.ReadOnlyField(source='reporter.id')
    reporter_name = serializers.SerializerMethodField()
    product_name = serializers.SerializerMethodField()

    class Meta:
        model = ProductReport
        fields = [
            'id',
            'reporter',
            'reporter_name',
            'product',
            'product_name',
            'reason',
            'details',
            'status',
            'created_at',
        ]
        read_only_fields = ['id', 'reporter', 'reporter_name', 'product_name', 'status', 'created_at']

    def get_reporter_name(self, obj):
        return obj.reporter.name or obj.reporter.username

    def get_product_name(self, obj):
        return obj.product.name

    def validate(self, attrs):
        request = self.context.get('request')
        reporter = getattr(request, 'user', None)
        product = attrs.get('product')
        if reporter and product and product.store_id == reporter.id:
            raise serializers.ValidationError('You cannot report your own product.')
        return attrs
