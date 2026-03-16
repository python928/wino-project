from django.contrib import admin
from django.utils.html import format_html
from django.utils import timezone

from .models import (
    MerchantSubscription,
    SubscriptionPaymentConfig,
    SubscriptionPaymentRequest,
    SubscriptionPaymentProof,
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
    readonly_fields = ('proof_gallery', 'reviewed_by', 'reviewed_at')
    fieldsets = (
        ('Details', {
            'fields': ('merchant', 'plan', 'status', 'status_reason_code', 'status_reason_text', 'reviewed_by', 'reviewed_at'),
            'classes': ('tab', 'tab-details'),
        }),
        ('Payment Proofs', {
            'fields': ('payment_note', 'proof_gallery'),
            'classes': ('tab', 'tab-proofs'),
        }),
    )

    class Media:
        css = {
            'all': ('subscriptions/admin_tabs.css',)
        }
        js = ('subscriptions/admin_tabs.js',)

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

        if obj.status in [SubscriptionPaymentRequest.STATUS_APPROVED, SubscriptionPaymentRequest.STATUS_REJECTED]:
            obj.reviewed_by = request.user
            if obj.reviewed_at is None:
                obj.reviewed_at = timezone.now()
        else:
            obj.reviewed_by = None
            obj.reviewed_at = None
            obj.status_reason_code = ''
            obj.status_reason_text = ''

        super().save_model(request, obj, form, change)

        # Transition to approved => activate subscription.
        if obj.status == SubscriptionPaymentRequest.STATUS_APPROVED and previous_status != obj.status:
            activate_subscription_for_payment_request(obj)

    @admin.display(description='Images')
    def proof_gallery(self, obj):
        proofs = list(obj.proofs.all())
        if not proofs:
            return '-'
        images = []
        for proof in proofs:
            if proof.image:
                images.append(
                    format_html(
                        '<a href="{0}" target="_blank" rel="noopener">'
                        '<img src="{0}" style="height: 160px; width: 160px; object-fit: cover; margin: 6px; border-radius: 10px; border: 1px solid #eee;" />'
                        '</a>',
                        proof.image.url,
                    )
                )
        return format_html(''.join(str(i) for i in images))



@admin.register(SubscriptionPaymentConfig)
class SubscriptionPaymentConfigAdmin(admin.ModelAdmin):
    list_display = ('rib', 'is_active', 'updated_at')
    list_filter = ('is_active',)
