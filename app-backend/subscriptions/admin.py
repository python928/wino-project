from django.contrib import admin
from django.utils.html import format_html

from .models import (
    MerchantSubscription,
    SubscriptionPaymentConfig,
    SubscriptionPaymentRequest,
    SubscriptionPlan,
)
from .services import activate_subscription_for_payment_request


@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'price', 'duration_days', 'max_products', 'promo_limit', 'is_active')

    @admin.display(description='Promo Audience')
    def promo_limit(self, obj):
        try:
            return (obj.plan_features or {}).get('promotion_max_impressions')
        except Exception:
            return '-'


@admin.register(MerchantSubscription)
class MerchantSubscriptionAdmin(admin.ModelAdmin):
    list_display = ('store', 'plan', 'status_icon', 'status', 'start_date', 'end_date')
    list_filter = ('status',)

    @admin.display(description='State')
    def status_icon(self, obj):
        if obj.status == 'active':
            return format_html('<span title="Active">✅</span>')
        return format_html('<span title="Expired">⛔</span>')


@admin.register(SubscriptionPaymentRequest)
class SubscriptionPaymentRequestAdmin(admin.ModelAdmin):
    list_display = ('merchant', 'plan', 'status_icon', 'status', 'created_at')
    list_filter = ('status', 'plan')

    @admin.display(description='State')
    def status_icon(self, obj):
        if obj.status == SubscriptionPaymentRequest.STATUS_APPROVED:
            return format_html('<span title="Approved">✅</span>')
        if obj.status == SubscriptionPaymentRequest.STATUS_REJECTED:
            return format_html('<span title="Rejected">❌</span>')
        return format_html('<span title="Pending">⏳</span>')

    def save_model(self, request, obj, form, change):
        previous_status = None
        if change and obj.pk:
            previous_status = (
                SubscriptionPaymentRequest.objects
                .filter(pk=obj.pk)
                .values_list('status', flat=True)
                .first()
            )

        super().save_model(request, obj, form, change)

        # Transition to approved => activate subscription.
        if obj.status == SubscriptionPaymentRequest.STATUS_APPROVED and previous_status != obj.status:
            activate_subscription_for_payment_request(obj)


@admin.register(SubscriptionPaymentConfig)
class SubscriptionPaymentConfigAdmin(admin.ModelAdmin):
    list_display = ('rib', 'is_active', 'updated_at')
    list_filter = ('is_active',)
