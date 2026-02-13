from django.contrib import admin

from .models import MerchantSubscription, SubscriptionPlan


@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'price', 'duration_days', 'max_products')


@admin.register(MerchantSubscription)
class MerchantSubscriptionAdmin(admin.ModelAdmin):
    list_display = ('store', 'plan', 'status', 'start_date', 'end_date')
    list_filter = ('status',)

# Register your models here.
