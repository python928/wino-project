import 'package:flutter/material.dart';
import '../../../core/routing/routes.dart';
import '../../../data/models/pack_model.dart';
import '../../../core/widgets/cards/unified_item_card.dart';
import '../../common/widgets/stacked_product_images.dart';

/// Unified Pack Card using UnifiedItemCard
/// Displays packs consistently across home, search, discovery, and profile screens
class PackCard extends StatelessWidget {
  final Pack pack;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;

  const PackCard({
    super.key,
    required this.pack,
    this.onTap,
    this.onEditTap,
  });

  String _buildProductSummary() {
    if (pack.products.isEmpty) return 'Empty pack';

    final maxItems = 3;
    final itemsToShow = pack.products.take(maxItems).toList();

    final validItems = itemsToShow.map((product) {
      // PackProduct object (from pack_model.dart)
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

  @override
  Widget build(BuildContext context) {
    final discountPercent = pack.totalPrice > 0
        ? ((pack.totalPrice - pack.discountPrice) / pack.totalPrice * 100).round()
        : 0;

    return UnifiedItemCard(
      title: '${pack.name}\n${_buildProductSummary()}',
      customImageWidget: StackedProductImages(products: pack.products),
      price: pack.discountPrice,
      oldPrice: pack.totalPrice > pack.discountPrice ? pack.totalPrice : null,
      discountPercentage: discountPercent > 0 ? discountPercent : null,
      customBadge: discountPercent > 0 ? 'Save $discountPercent%' : null,
      bottomLeftText: '${pack.products.length} product${pack.products.length == 1 ? '' : 's'}',
      bottomLeftIcon: Icons.inventory_2_outlined,
      onTap: onTap ?? () {
        Navigator.pushNamed(context, Routes.packDetails, arguments: pack);
      },
      onEditTap: onEditTap,
    );
  }
}
