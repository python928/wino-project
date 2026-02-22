from django.contrib import admin

from .models import InteractionLog, UserInterestProfile


@admin.register(UserInterestProfile)
class UserInterestProfileAdmin(admin.ModelAdmin):
	list_display = ('id', 'user', 'last_updated')
	search_fields = ('user__username', 'user__email')


@admin.register(InteractionLog)
class InteractionLogAdmin(admin.ModelAdmin):
	list_display = ('id', 'user', 'action', 'product', 'category', 'timestamp')
	list_filter = ('action', 'timestamp')
	search_fields = ('user__username', 'user__email', 'session_id')
