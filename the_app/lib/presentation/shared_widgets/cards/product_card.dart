import 'package:flutter/material.dart';
import '../../../core/routing/routes.dart';
import '../../../data/models/post_model.dart';
import '../../../core/widgets/cards/base_item_card.dart';

/// Product Card inheriting from BaseItemCard
/// Provides standardized product display with store navigation
class ProductCard extends BaseItemCard {
  final Post product;
  final VoidCallback? onFavoriteTap;
  final bool showUnavailableOverlay;
  final bool showStoreName;

  ProductCard({
    super.key,
    required this.product,
    VoidCallback? onTap,
    this.onFavoriteTap,
    VoidCallback? onEditTap,
    this.showUnavailableOverlay = false,
    this.showStoreName = true,
  }) : super(
          title: product.title,
          imageUrl: product.image,
          price: product.price,
          oldPrice: product.oldPrice,
          hidePrice: product.hidePrice,
          discountPercentage: _calculateDiscountPercent(product),
          rating: product.rating,
          reviewCount: product.reviewCount,
          bottomLeftText: product.storeAddress.isNotEmpty
              ? product.storeAddress
              : (showStoreName ? product.storeName : null),
          bottomLeftIcon: product.storeAddress.isNotEmpty
              ? Icons.location_on_outlined
              : null,
          isUnavailable: !product.isAvailable,
          showUnavailableOverlay: showUnavailableOverlay,
          onTap: (product.isAvailable || onEditTap != null) ? onTap : null,
          onEditTap: onEditTap,
        );

  static int? _calculateDiscountPercent(Post product) {
    if (product.oldPrice == null || product.oldPrice! <= product.price) {
      return null;
    }
    return product.discountPercentage ??
        ((product.oldPrice! - product.price) / product.oldPrice! * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    // Override to provide context-aware navigation
    return BaseItemCard(
      title: title,
      imageUrl: imageUrl,
      price: price,
      oldPrice: oldPrice,
      hidePrice: hidePrice,
      discountPercentage: discountPercentage,
      rating: rating,
      reviewCount: reviewCount,
      bottomLeftText: bottomLeftText,
      bottomLeftIcon: bottomLeftIcon,
      isUnavailable: isUnavailable,
      showUnavailableOverlay: showUnavailableOverlay,
      onTap: onTap,
      onEditTap: onEditTap,
      onBottomLeftTap: () => _navigateToStore(context),
    );
  }

  void _navigateToStore(BuildContext context) {
    Navigator.pushNamed(context, Routes.store, arguments: product.storeId);
  }
}
