from rest_framework import serializers

from .models import Promotion, PromotionImage


class PromotionImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PromotionImage
        fields = ['id', 'promotion', 'image', 'is_main']
        read_only_fields = ['id']


class PromotionSerializer(serializers.ModelSerializer):
    images = PromotionImageSerializer(many=True, read_only=True)

    class Meta:
        model = Promotion
        fields = [
            'id',
            'store',
            'product',
            'name',
            'description',
            'percentage',
            'start_date',
            'end_date',
            'images',
        ]
        read_only_fields = ['id']
