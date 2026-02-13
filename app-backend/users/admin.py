from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User, Follower


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

# Register your models here.
