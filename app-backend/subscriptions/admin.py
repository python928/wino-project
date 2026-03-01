from django.contrib import admin

from .models import (
    MerchantSubscription,
    SubscriptionPaymentConfig,
    SubscriptionPaymentRequest,
    SubscriptionPlan,
)


@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'price', 'duration_days', 'max_products', 'is_active')


@admin.register(MerchantSubscription)
class MerchantSubscriptionAdmin(admin.ModelAdmin):
    list_display = ('store', 'plan', 'status', 'start_date', 'end_date')
    list_filter = ('status',)


@admin.register(SubscriptionPaymentRequest)
class SubscriptionPaymentRequestAdmin(admin.ModelAdmin):
    list_display = ('merchant', 'plan', 'status', 'created_at')
    list_filter = ('status', 'plan')


@admin.register(SubscriptionPaymentConfig)
class SubscriptionPaymentConfigAdmin(admin.ModelAdmin):
    list_display = ('rib', 'is_active', 'updated_at')
    list_filter = ('is_active',)
