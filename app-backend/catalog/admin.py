from django.contrib import admin

from .models import (
	Category,
	Pack,
	PackImage,
	PackProduct,
	Product,
	ProductImage,
	Review,
	Favorite,
)


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
	list_display = ('name', 'parent')
	search_fields = ('name',)


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
	list_display = ('user', 'product', 'rating', 'comment_preview', 'created_at')
	search_fields = ('user__username', 'product__name', 'comment')
	list_filter = ('rating', 'created_at')
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
