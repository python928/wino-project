from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User, Follower, PhoneOTP, StoreReport


@admin.register(User)
class CustomUserAdmin(UserAdmin):
	fieldsets = (
		(None, {'fields': ('username', 'password')}),
		('Personal info', {'fields': ('name', 'email', 'phone', 'profile_image', 'gender', 'birthday')}),
		('Store Info', {'fields': ('store_description', 'address', 'latitude', 'longitude', 'allow_nearby_visibility', 'location_updated_at', 'store_type', 'cover_image')}),
		('Social', {'fields': ('facebook', 'instagram', 'whatsapp', 'tiktok', 'youtube')}),
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
	list_display = ('username', 'email', 'name', 'address', 'allow_nearby_visibility', 'is_active', 'is_staff')
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
	list_display = ('reporter', 'store', 'reason', 'status', 'created_at')
	search_fields = ('reporter__username', 'store__username', 'details')
	list_filter = ('reason', 'status')
