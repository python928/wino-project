from rest_framework import serializers
from django.db.models import Avg

from .models import Category, Pack, PackImage, PackProduct, Product, ProductImage, Review, Favorite


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
    images = ProductImageSerializer(many=True, read_only=True)
    average_rating = serializers.SerializerMethodField()
    review_count = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            'id',
            'store',
            'category',
            'name',
            'description',
            'price',
            'negotiable',
            'available_status',
            'created_at',
            'images',
            'average_rating',
            'review_count',
            'is_favorited',
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


class PackProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = PackProduct
        fields = ['id', 'pack', 'product']
        read_only_fields = ['id']


class PackImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PackImage
        fields = ['id', 'pack', 'image', 'is_main']
        read_only_fields = ['id']


class PackSerializer(serializers.ModelSerializer):
    pack_products = PackProductSerializer(many=True, read_only=True)
    images = PackImageSerializer(many=True, read_only=True)

    class Meta:
        model = Pack
        fields = ['id', 'store', 'name', 'description', 'discount', 'created_at', 'pack_products', 'images']
        read_only_fields = ['id', 'created_at']


class ReviewSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.id')
    user_name = serializers.SerializerMethodField()
    username = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = Review
        fields = ['id', 'user', 'user_name', 'username', 'store', 'product', 'rating', 'comment', 'created_at']
        read_only_fields = ['id', 'user', 'user_name', 'username', 'store', 'created_at']

    def get_user_name(self, obj):
        if obj.user.first_name or obj.user.last_name:
            return f"{obj.user.first_name} {obj.user.last_name}".strip()
        return obj.user.username


class FavoriteSerializer(serializers.ModelSerializer):
    product_detail = ProductSerializer(source='product', read_only=True)

    class Meta:
        model = Favorite
        fields = ['id', 'user', 'product', 'product_detail', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']
