import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/pack_model.dart';

/// Widget to display stacked product images for pack items
/// Shows up to 4 product images in a mosaic layout
class StackedProductImages extends StatelessWidget {
  final List<dynamic> products;

  const StackedProductImages({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.15),
              AppColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.shopping_bag,
          size: 45,
          color: AppColors.primary,
        ),
      );
    }

    return _buildMosaicPackImages(context);
  }

  Widget _buildMosaicPackImages(BuildContext context) {
    final hiddenProductsCount = (products.length - 4).clamp(0, products.length);
    final tile0 = products.isNotEmpty ? products[0] : null;
    final tile1 = products.length > 1 ? products[1] : null;
    final tile2 = products.length > 2 ? products[2] : null;
    final tile3 = products.length > 3 ? products[3] : null;

    return Container(
      color: const Color(0xFFF3F4F7),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildTile(tile0)),
                const SizedBox(width: 2),
                Expanded(child: _buildTile(tile1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildTile(tile2)),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildTile(tile3),
                      if (hiddenProductsCount > 0)
                        Center(
                          child: _buildCountPill(context, hiddenProductsCount),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(dynamic product) {
    if (product == null) {
      return Container(
        color: const Color(0xFFF0F1F4),
      );
    }

    return _buildProductImage(product, fit: BoxFit.cover);
  }

  Widget _buildCountPill(BuildContext context, int hiddenProductsCount) {
    final isArabic =
        Localizations.maybeLocaleOf(context)?.languageCode.toLowerCase() ==
            'ar';
    final fullLabel = isArabic
        ? '+$hiddenProductsCount إضافية'
        : '+$hiddenProductsCount more';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 92;
        final label = isNarrow ? '+$hiddenProductsCount' : fullLabel;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 8 : 12,
              vertical: isNarrow ? 5 : 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF2E2E32),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!isNarrow) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: AppColors.purpleGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.widgets_outlined,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductImage(dynamic product, {BoxFit fit = BoxFit.cover}) {
    String? imageUrl;

    // Handle PackProduct object
    if (product is PackProduct) {
      imageUrl = product.productImage;
    } else if (product is Map<String, dynamic>) {
      imageUrl = product['product_image'] as String?;
    }

    // Get the full image URL using ApiConfig
    final fullImageUrl = ApiConfig.getImageUrl(imageUrl);

    if (fullImageUrl.isEmpty) {
      return Container(
        color: Colors.grey[100],
        alignment: Alignment.center,
        child: const Icon(
          Icons.inventory_2,
          size: 28,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      fullImageUrl,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[100],
        alignment: Alignment.center,
        child: const Icon(
          Icons.inventory_2,
          size: 28,
          color: Colors.grey,
        ),
      ),
    );
  }
}
