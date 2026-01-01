from rest_framework import serializers

from .models import MerchantSubscription, SubscriptionPlan


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = ['id', 'name', 'max_products', 'price', 'duration_days']
        read_only_fields = ['id']


class MerchantSubscriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = MerchantSubscription
        fields = ['id', 'store', 'plan', 'start_date', 'end_date', 'status']
        read_only_fields = ['id']
