from django.contrib import admin
from django.utils.html import format_html

from .models import CoinPackPlan, CoinPurchase, CoinTransaction
from .services import approve_coin_purchase


@admin.register(CoinTransaction)
class CoinTransactionAdmin(admin.ModelAdmin):
	list_display = ('id', 'user', 'amount_signed', 'reason', 'created_at')
	list_filter = ('reason', 'created_at')
	search_fields = ('user__username', 'user__name', 'reason', 'related_model')
	ordering = ('-created_at',)


@admin.register(CoinPurchase)
class CoinPurchaseAdmin(admin.ModelAdmin):
	list_display = (
		'id',
		'status_marker',
		'user',
		'coins_amount',
		'price_amount',
		'created_at',
	)
	list_filter = ('status', 'created_at')
	search_fields = ('user__username', 'user__name', 'pack_id', 'payment_note')
	ordering = ('-created_at',)
	actions = ['approve_selected']
	readonly_fields = ('proof_gallery',)
	fieldsets = (
		('Purchase', {
			'fields': (
				'user',
				'pack_id',
				'coins_amount',
				'price_amount',
				'status',
			),
		}),
		('Proofs', {
			'fields': ('payment_note', 'proof_gallery'),
		}),
	)

	@admin.action(description='Approve selected pending purchases')
	def approve_selected(self, request, queryset):
		approved = 0
		for purchase in queryset:
			_, credited = approve_coin_purchase(purchase, approver=request.user)
			if credited:
				approved += 1
		self.message_user(request, f'Approved {approved} purchase(s).')

	def save_model(self, request, obj, form, change):
		# Keep approval metadata automatic and hidden from admin form.
		previous_status = None
		if change and obj.pk:
			previous_status = (
				CoinPurchase.objects.filter(pk=obj.pk).values_list('status', flat=True).first()
			)

		should_auto_approve = (
			change
			and obj.pk is not None
			and obj.status == CoinPurchase.STATUS_COMPLETED
			and previous_status != CoinPurchase.STATUS_COMPLETED
		)

		if should_auto_approve:
			# Save other edited fields while keeping purchase non-completed,
			# then run canonical approval flow that credits coins exactly once.
			obj.status = previous_status or CoinPurchase.STATUS_PENDING
			super().save_model(request, obj, form, change)
			purchase = CoinPurchase.objects.get(pk=obj.pk)
			approve_coin_purchase(purchase, approver=request.user)
			return

		super().save_model(request, obj, form, change)

	@admin.display(description='Status')
	def status_marker(self, obj):
		if obj.status == CoinPurchase.STATUS_COMPLETED:
			return format_html(
				'<span title="Approved" style="display:inline-flex;align-items:center;gap:6px;color:#0f6a3d;font-weight:800;">'
				'✔ Approved'
				'</span>'
			)
		if obj.status == CoinPurchase.STATUS_FAILED:
			return format_html(
				'<span title="Rejected" style="display:inline-flex;align-items:center;gap:6px;color:#a61b1b;font-weight:800;">'
				'✖ Rejected'
				'</span>'
			)
		return format_html(
			'<span title="Pending" style="display:inline-flex;align-items:center;gap:6px;color:#8a6300;font-weight:800;">'
			'⏳ Pending'
			'</span>'
		)

	@admin.display(description='Payment proof images')
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
						'<img src="{0}" style="height: 140px; width: 140px; object-fit: cover; margin: 6px; border-radius: 10px; border: 1px solid #eee;" />'
						'</a>',
						proof.image.url,
					)
				)
		return format_html(''.join(str(item) for item in images))


@admin.register(CoinPackPlan)
class CoinPackPlanAdmin(admin.ModelAdmin):
	list_display = (
		'title',
		'pack_id',
		'coins_amount',
		'price_amount',
		'original_price_amount',
		'is_promoted',
		'promo_badge',
		'sort_order',
		'is_active',
	)
	list_filter = ('is_active',)
	search_fields = ('pack_id', 'title')
	ordering = ('sort_order', 'coins_amount', 'id')
	fieldsets = (
		('Plan', {
			'fields': (
				'title',
				'pack_id',
				'coins_amount',
				'price_amount',
				'original_price_amount',
				'is_promoted',
				'promo_badge',
				'sort_order',
				'is_active',
			),
		}),
	)
