from rest_framework import serializers

from .models import (
    MerchantSubscription,
    SubscriptionPaymentConfig,
    SubscriptionPaymentRequest,
    SubscriptionPlan,
)


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = [
            'id',
            'name',
            'slug',
            'max_products',
            'price',
            'duration_days',
            'benefits',
            'is_active',
        ]
        read_only_fields = ['id']


class MerchantSubscriptionSerializer(serializers.ModelSerializer):
    plan_detail = SubscriptionPlanSerializer(source='plan', read_only=True)

    class Meta:
        model = MerchantSubscription
        fields = ['id', 'store', 'plan', 'plan_detail', 'start_date', 'end_date', 'status']
        read_only_fields = ['id']


class SubscriptionPaymentRequestSerializer(serializers.ModelSerializer):
    merchant = serializers.ReadOnlyField(source='merchant.id')
    plan_detail = SubscriptionPlanSerializer(source='plan', read_only=True)

    class Meta:
        model = SubscriptionPaymentRequest
        fields = [
            'id',
            'merchant',
            'plan',
            'plan_detail',
            'status',
            'payment_note',
            'created_at',
        ]
        read_only_fields = ['id', 'merchant', 'status', 'created_at', 'plan_detail']


class SubscriptionPaymentConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPaymentConfig
        fields = ['id', 'rib', 'instructions', 'is_active', 'updated_at']
        read_only_fields = ['id', 'updated_at']
