import 'package:flutter/material.dart';
import '../../../core/routing/routes.dart';
import '../../../data/models/post_model.dart';
import '../../../core/widgets/cards/base_item_card.dart';
import '../../../core/utils/helpers.dart';

/// Product Card inheriting from BaseItemCard
/// Provides standardized product display with store navigation
class ProductCard extends BaseItemCard {
  final Post product;
  final VoidCallback? onFavoriteTap;
  final double? userLat;
  final double? userLng;
  final String? customBadge;

  ProductCard({
    super.key,
    required this.product,
    VoidCallback? onTap,
    this.onFavoriteTap,
    VoidCallback? onEditTap,
    bool showUnavailableOverlay = false,
    bool showStoreName = true,
    this.userLat,
    this.userLng,
    this.customBadge,
  }) : super(
          title: product.title,
          imageUrl: product.image,
          price: product.price,
          oldPrice: product.oldPrice,
          hidePrice: product.hidePrice,
          discountPercentage: _calculateDiscountPercent(product),
          customBadge: customBadge,
          rating: product.rating,
          reviewCount: product.reviewCount,
          bottomLeftText:
              _buildBottomText(product, showStoreName, userLat, userLng),
          bottomLeftIcon: Icons.location_on_outlined,
          isUnavailable: !product.isAvailable,
          showUnavailableOverlay: showUnavailableOverlay,
          onTap: (product.isAvailable || onEditTap != null) ? onTap : null,
          onEditTap: onEditTap,
        );

  static String? _buildBottomText(
      Post product, bool showStoreName, double? userLat, double? userLng) {
    if (!showStoreName) return null;
    // Prefer showing distance if we have both user and store coordinates
    final dist = Helpers.haversineDistance(
      userLat,
      userLng,
      product.storeLatitude,
      product.storeLongitude,
    );
    if (dist != null) {
      return Helpers.formatDistance(dist);
    }
    // Fallback to store address
    if (product.storeAddress.isNotEmpty) return product.storeAddress;
    return product.storeName;
  }

  static int? _calculateDiscountPercent(Post product) {
    if (product.oldPrice == null || product.oldPrice! <= product.price) {
      return null;
    }
    return product.discountPercentage ??
        ((product.oldPrice! - product.price) / product.oldPrice! * 100).round();
  }

  @override
  Widget? buildCustomBottomInfo(BuildContext context) {
    // Show custom badge text as status info if present
    if (customBadge != null && customBadge!.isNotEmpty) {
      final isUnavailable =
          customBadge!.toLowerCase().contains('not available');

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isUnavailable
              ? const Color(0xFFFFF2E2).withOpacity(0.8)
              : const Color(0xFFFFF9E6).withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          customBadge!,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isUnavailable
                ? const Color(0xFF8A4B08)
                : const Color(0xFF8A4B08),
          ),
        ),
      );
    }
    return null;
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
      customBadge: customBadge,
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
