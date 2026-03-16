from django.contrib import admin

from .models import AdCampaign, AdCampaignViewer


@admin.register(AdCampaign)
class AdCampaignAdmin(admin.ModelAdmin):
	list_display = ('id', 'name', 'store', 'product', 'pack', 'is_active', 'impressions_count', 'clicks_count', 'created_at')
	list_filter = ('is_active', 'placement', 'audience_mode')
	search_fields = ('name', 'store__username', 'store__name')


@admin.register(AdCampaignViewer)
class AdCampaignViewerAdmin(admin.ModelAdmin):
	list_display = ('id', 'campaign', 'viewer_key', 'first_seen_at', 'last_seen_at')
	search_fields = ('viewer_key',)
