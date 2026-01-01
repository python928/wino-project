from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User


@admin.register(User)
class CustomUserAdmin(UserAdmin):
	fieldsets = UserAdmin.fieldsets + (
		('Profile', {'fields': ('phone', 'role', 'profile_image')}),
	)
	list_display = ('username', 'email', 'role', 'is_active', 'is_staff')
	list_filter = ('role', 'is_staff', 'is_active')

# Register your models here.
