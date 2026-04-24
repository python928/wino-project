from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User, Follower, PhoneOTP, StoreReport, SystemSettings, TrustSettings, AbuseFlag


@admin.register(User)
class CustomUserAdmin(UserAdmin):
	fieldsets = (
		(None, {'fields': ('username', 'password')}),
		('Personal info', {'fields': ('name', 'email', 'phone', 'profile_image', 'gender', 'birthday')}),
		('Store Info', {'fields': ('store_description', 'address', 'latitude', 'longitude', 'allow_nearby_visibility', 'location_updated_at', 'store_type', 'cover_image')}),
		('Social', {'fields': ('facebook', 'instagram', 'whatsapp', 'tiktok', 'youtube', 'show_phone_public', 'show_social_public')}),
		('Trust & Verification', {'fields': ('verification_status', 'is_verified', 'verified_at', 'verified_by', 'verification_note')}),
		('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
		('Important dates', {'fields': ('last_login', 'date_joined')}),
	)
	add_fieldsets = (
		(
			None,
			{
				'classes': ('wide',),
				'fields': ('username', 'name', 'email', 'password1', 'password2', 'is_staff', 'is_active'),
			},
		),
	)
	list_display = ('username', 'email', 'name', 'address', 'is_verified', 'allow_nearby_visibility', 'is_active', 'is_staff')
	list_filter = ('store_type', 'allow_nearby_visibility', 'is_staff', 'is_active')
	search_fields = ('username', 'name', 'email', 'phone', 'address')
	ordering = ('-date_joined',)


@admin.register(Follower)
class FollowerAdmin(admin.ModelAdmin):
	list_display = ('user', 'followed_user', 'created_at')
	search_fields = ('user__username', 'followed_user__username')


@admin.register(PhoneOTP)
class PhoneOTPAdmin(admin.ModelAdmin):
	list_display = ('phone', 'code', 'created_at', 'expires_at', 'attempts', 'is_verified')
	search_fields = ('phone',)
	list_filter = ('is_verified',)


@admin.register(StoreReport)
class StoreReportAdmin(admin.ModelAdmin):
	list_display = ('reporter', 'store', 'reason', 'status', 'seriousness_level', 'seriousness_score', 'created_at')
	search_fields = ('reporter__username', 'store__username', 'details')
	list_filter = ('reason', 'status', 'seriousness_level', 'is_low_credibility')

@admin.register(SystemSettings)
class SystemSettingsAdmin(admin.ModelAdmin):
	list_display = ('first_login_coins', 'daily_login_coins')

	# Prevent adding more than one setting
	def has_add_permission(self, request):
		from .models import SystemSettings
		if SystemSettings.objects.exists():
			return False
		return super().has_add_permission(request)


@admin.register(TrustSettings)
class TrustSettingsAdmin(admin.ModelAdmin):
	list_display = (
		'report_quick_submit_seconds',
		'review_quick_submit_seconds',
		'minimum_interactions_for_high_credibility',
		'auto_verify_eligible_stores',
	)

	def has_add_permission(self, request):
		if TrustSettings.objects.exists():
			return False
		return super().has_add_permission(request)


@admin.register(AbuseFlag)
class AbuseFlagAdmin(admin.ModelAdmin):
	list_display = ('actor', 'signal_type', 'target_type', 'target_id', 'count', 'last_seen_at')
	list_filter = ('signal_type', 'target_type', 'last_seen_at')
	search_fields = ('actor__username', 'actor__email')
