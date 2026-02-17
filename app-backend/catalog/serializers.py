from rest_framework import serializers
from django.db.models import Avg

from .models import Category, Pack, PackImage, PackProduct, Product, ProductImage, Review, Favorite, Promotion, PromotionImage


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'parent']


class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['id', 'product', 'image', 'is_main']
        read_only_fields = ['id']


class ProductSerializer(serializers.ModelSerializer):
    store = serializers.PrimaryKeyRelatedField(read_only=True)
    images = ProductImageSerializer(many=True, read_only=True)
    average_rating = serializers.SerializerMethodField()
    review_count = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()
    store_name = serializers.SerializerMethodField()

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
            'created_at',
            'images',
            'average_rating',
            'review_count',
            'is_favorited',
            'store_name',
        ]
        read_only_fields = ['id', 'created_at']

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
        # store == users.User
        return getattr(obj.store, 'name', None) or getattr(obj.store, 'username', '')


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
    merchant_id = serializers.IntegerField(source='merchant_id', read_only=True)
    merchant_name = serializers.CharField(source='merchant.name', read_only=True)
    discount_price = serializers.DecimalField(source='discount', max_digits=10, decimal_places=2)
    total_price = serializers.SerializerMethodField()

    class Meta:
        model = Pack
        fields = ['id', 'merchant_id', 'merchant_name', 'name', 'description', 'discount_price', 'total_price', 'available_status', 'created_at', 'pack_products', 'images', 'products']
        read_only_fields = ['id', 'created_at', 'pack_products', 'images']

    def get_total_price(self, obj):
        return sum(pp.product.price * pp.quantity for pp in obj.pack_products.all())

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
