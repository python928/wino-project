from django.contrib import admin

from .models import Notification, NotificationRecipient


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('actor', 'notification_type', 'title', 'created_at')
    list_filter = ('notification_type', 'created_at')
    search_fields = ('title', 'body')


@admin.register(NotificationRecipient)
class NotificationRecipientAdmin(admin.ModelAdmin):
    list_display = ('notification', 'user', 'is_read', 'delivered_at')
    list_filter = ('is_read', 'delivered_at')
    search_fields = ('notification__title', 'user__username')

# Register your models here.
