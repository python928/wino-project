from django.contrib import admin

from .models import Message


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
	list_display = ('sender', 'receiver', 'created_at', 'read_status')
	search_fields = ('sender__username', 'receiver__username', 'content')

# Register your models here.
