from rest_framework import serializers

from .models import (
    MerchantSubscription,
    SubscriptionPaymentConfig,
    SubscriptionPaymentRequest,
    SubscriptionPaymentProof,
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
            'plan_features',
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
    proofs = serializers.SerializerMethodField()
    reviewed_by = serializers.ReadOnlyField(source='reviewed_by.id')
    timeline = serializers.SerializerMethodField()

    def get_proofs(self, obj):
        return [
            {
                'id': proof.id,
                'image': proof.image.url if proof.image else '',
                'created_at': proof.created_at,
            }
            for proof in obj.proofs.all()
        ]

    def get_timeline(self, obj):
        events = [
            {
                'event': 'submitted',
                'status': 'pending',
                'at': obj.created_at,
                'note': 'Payment request submitted.',
            }
        ]
        if obj.status in [SubscriptionPaymentRequest.STATUS_APPROVED, SubscriptionPaymentRequest.STATUS_REJECTED]:
            events.append(
                {
                    'event': obj.status,
                    'status': obj.status,
                    'at': obj.reviewed_at or obj.created_at,
                    'reason_code': obj.status_reason_code,
                    'reason_text': obj.status_reason_text,
                }
            )
        return events

    class Meta:
        model = SubscriptionPaymentRequest
        fields = [
            'id',
            'merchant',
            'plan',
            'plan_detail',
            'status',
            'payment_note',
            'status_reason_code',
            'status_reason_text',
            'reviewed_by',
            'reviewed_at',
            'created_at',
            'proofs',
            'timeline',
        ]
        read_only_fields = [
            'id',
            'merchant',
            'status',
            'created_at',
            'plan_detail',
            'reviewed_by',
            'reviewed_at',
            'timeline',
        ]


class SubscriptionPaymentConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPaymentConfig
        fields = ['id', 'rib', 'instructions', 'is_active', 'updated_at']
        read_only_fields = ['id', 'updated_at']
