from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User, Follower, PhoneOTP


@admin.register(User)
class CustomUserAdmin(UserAdmin):
	fieldsets = UserAdmin.fieldsets + (
		('Profile', {'fields': ('phone', 'profile_image')}),
		('Store Info', {'fields': ('store_description', 'address', 'latitude', 'longitude', 'store_type', 'cover_image')}),
	)
	list_display = ('username', 'email', 'name', 'address', 'is_active', 'is_staff')
	list_filter = ('store_type', 'is_staff', 'is_active')


@admin.register(Follower)
class FollowerAdmin(admin.ModelAdmin):
	list_display = ('user', 'followed_user', 'created_at')
	search_fields = ('user__username', 'followed_user__username')


@admin.register(PhoneOTP)
class PhoneOTPAdmin(admin.ModelAdmin):
	list_display = ('phone', 'code', 'created_at', 'expires_at', 'attempts', 'is_verified')
	search_fields = ('phone',)
	list_filter = ('is_verified',)

# Register your models here.
