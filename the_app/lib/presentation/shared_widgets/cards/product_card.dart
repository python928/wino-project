import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/post_model.dart';
import '../../../core/widgets/cards/unified_item_card.dart';

class ProductCard extends StatelessWidget {
  final Post product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onEditTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoriteTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.oldPrice != null && product.oldPrice! > product.price;
    final discountPercent = hasDiscount
        ? product.discountPercentage ??
            ((product.oldPrice! - product.price) / product.oldPrice! * 100).round()
        : null;

    return UnifiedItemCard(
      title: product.title,
      imageUrl: product.image,
      price: product.price,
      oldPrice: hasDiscount ? product.oldPrice : null,
      hidePrice: product.hidePrice,
      discountPercentage: discountPercent,
      rating: product.rating,
      bottomLeftText: product.storeName,
      isUnavailable: !product.isAvailable,
      onTap: (product.isAvailable || onEditTap != null) ? onTap : null,
      onEditTap: onEditTap,
      onBottomLeftTap: () => _navigateToStore(context),
    );
  }

  void _navigateToStore(BuildContext context) {
    // Check if this is the user's own store
    final userData = StorageService.getUserData();
    final userStoreId = userData?['store_id'];

    if (userStoreId != null && product.storeId == userStoreId) {
      // Navigate to own profile
      Navigator.pushNamed(context, Routes.profile);
    } else {
      // Navigate to the product publisher's store
      Navigator.pushNamed(context, Routes.store, arguments: product.storeId);
    }
  }
}
