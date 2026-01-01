from django.contrib import admin

from .models import Follower, Store


@admin.register(Store)
class StoreAdmin(admin.ModelAdmin):
	list_display = ('name', 'owner', 'type', 'created_at')
	search_fields = ('name', 'owner__username')


@admin.register(Follower)
class FollowerAdmin(admin.ModelAdmin):
	list_display = ('user', 'store', 'created_at')
	search_fields = ('user__username', 'store__name')

# Register your models here.
