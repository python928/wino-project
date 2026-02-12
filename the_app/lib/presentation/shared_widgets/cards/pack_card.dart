import 'package:flutter/material.dart';
import '../../../core/routing/routes.dart';
import '../../../data/models/pack_model.dart';
import '../../../core/widgets/cards/base_item_card.dart';
import '../../common/widgets/stacked_product_images.dart';

/// Pack Card inheriting from BaseItemCard
/// Displays packs with custom image widget and specialized content
class PackCard extends BaseItemCard {
  final Pack pack;

  PackCard({
    super.key,
    required this.pack,
    VoidCallback? onTap,
    VoidCallback? onEditTap,
  }) : super(
          title: '${pack.name}\n${_buildProductSummary(pack)}',
          price: pack.discountPrice,
          oldPrice: pack.totalPrice > pack.discountPrice ? pack.totalPrice : null,
          discountPercentage: _calculateDiscountPercent(pack),
          customBadge: _buildCustomBadge(pack),
          bottomLeftText: '${pack.products.length} product${pack.products.length == 1 ? '' : 's'}',
          bottomLeftIcon: Icons.inventory_2_outlined,
          customImageWidget: StackedProductImages(products: pack.products),
          onTap: onTap,
          onEditTap: onEditTap,
        );

  static String _buildProductSummary(Pack pack) {
    if (pack.products.isEmpty) return 'Empty pack';

    const maxItems = 3;
    final itemsToShow = pack.products.take(maxItems).toList();

    final validItems = itemsToShow.map((product) {
      final quantity = product.quantity;
      final name = product.productName.trim();

      if (name.isNotEmpty && name != 'null') {
        return '$quantity $name';
      }
      return null;
    }).where((item) => item != null).toList();

    if (validItems.isEmpty) {
      return '${pack.products.length} products';
    }

    String summary = validItems.join(' + ');

    if (pack.products.length > maxItems) {
      summary += ' ...';
    }

    return summary;
  }

  static int? _calculateDiscountPercent(Pack pack) {
    if (pack.totalPrice <= 0 || pack.discountPrice >= pack.totalPrice) {
      return null;
    }
    return ((pack.totalPrice - pack.discountPrice) / pack.totalPrice * 100).round();
  }

  static String? _buildCustomBadge(Pack pack) {
    final discountPercent = _calculateDiscountPercent(pack);
    return discountPercent != null && discountPercent > 0 ? 'Save $discountPercent%' : null;
  }

  @override
  Widget build(BuildContext context) {
    return BaseItemCard(
      title: title,
      price: price,
      oldPrice: oldPrice,
      discountPercentage: discountPercentage,
      customBadge: customBadge,
      bottomLeftText: bottomLeftText,
      bottomLeftIcon: bottomLeftIcon,
      customImageWidget: customImageWidget,
      onTap: onTap ?? () {
        Navigator.pushNamed(context, Routes.packDetails, arguments: pack);
      },
      onEditTap: onEditTap,
    );
  }
}
