from django.contrib import admin

from .models import Promotion, PromotionImage


class PromotionImageInline(admin.TabularInline):
	model = PromotionImage
	extra = 0


@admin.register(Promotion)
class PromotionAdmin(admin.ModelAdmin):
	list_display = ('name', 'store', 'percentage', 'start_date', 'end_date')
	inlines = [PromotionImageInline]

# Register your models here.
