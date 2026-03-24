from django.contrib import admin

from .models import (
	Category,
	Pack,
	PackImage,
	PackProduct,
	Product,
	ProductImage,
	ProductReport,
	Review,
	Favorite,
)


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
	list_display = ('name', 'name_ar', 'name_fr', 'name_en', 'icon_preview')
	search_fields = ('name', 'name_ar', 'name_fr', 'name_en')

	def icon_preview(self, obj):
		from django.utils.html import format_html
		if obj.icon_code_point:
			return format_html(
				'<span style="background:#f0eeff;color:#5b4fcf;'
				'padding:2px 10px;border-radius:12px;'
				'font-family:monospace;font-size:13px;">'
				'{}</span>',
				obj.icon_code_point,
			)
		return format_html('<span style="color:#aaa;">—</span>')
	icon_preview.short_description = 'Code Point'

	fieldsets = (
		(None, {
			'fields': ('name', 'name_ar', 'name_fr', 'name_en', 'icon_code_point', 'icon_font_family', 'icon_font_package'),
			'description': (
				'<b>icon_code_point</b>: Enter the hex code from '
				'<a href="https://fonts.google.com/icons?selected=Material+Icons" target="_blank">'
				'fonts.google.com/icons?selected=Material+Icons</a> '
				'(e.g. <code>e88a</code> for home). '
				'<br>⚠️ <b>CRITICAL:</b> On the website, ensure <b>"Material Icons"</b> is selected in the filters. '
				'Do NOT use "Material Symbols" codes (like e6b8) as they will show wrong icons.'
			),
		}),
	)


class ProductImageInline(admin.TabularInline):
	model = ProductImage
	extra = 0


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
	list_display = ('name', 'store', 'category', 'price', 'created_at')
	list_filter = ('category', 'available_status', 'store')
	search_fields = ('name', 'store__name', 'store__username')
	inlines = [ProductImageInline]


class PackProductInline(admin.TabularInline):
	model = PackProduct
	extra = 0


class PackImageInline(admin.TabularInline):
	model = PackImage
	extra = 0


@admin.register(Pack)
class PackAdmin(admin.ModelAdmin):
	list_display = ('name', 'merchant', 'discount', 'created_at')
	inlines = [PackProductInline, PackImageInline]


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
	list_display = ('user', 'product', 'rating', 'credibility_level', 'credibility_score', 'comment_preview', 'created_at')
	search_fields = ('user__username', 'product__name', 'comment')
	list_filter = ('rating', 'credibility_level', 'is_low_credibility', 'created_at')
	readonly_fields = ('user', 'created_at')

	def comment_preview(self, obj):
		if obj.comment:
			return obj.comment[:50] + '...' if len(obj.comment) > 50 else obj.comment
		return '-'
	comment_preview.short_description = 'Comment'


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
	list_display = ('user', 'product', 'created_at')
	search_fields = ('user__username', 'product__name')
	list_filter = ('created_at',)
	readonly_fields = ('created_at',)


@admin.register(ProductReport)
class ProductReportAdmin(admin.ModelAdmin):
	list_display = ('reporter', 'product', 'reason', 'status', 'seriousness_level', 'seriousness_score', 'created_at')
	search_fields = ('reporter__username', 'product__name', 'details')
	list_filter = ('reason', 'status', 'seriousness_level', 'is_low_credibility')
