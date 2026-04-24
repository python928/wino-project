import 'package:flutter/material.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/cards/base_item_card.dart';
import '../../../data/models/post_model.dart';

/// Product Card inheriting from BaseItemCard
/// Provides standardized product display with store navigation
class ProductCard extends BaseItemCard {
  final Post product;
  final VoidCallback? onFavoriteTap;
  final double? userLat;
  final double? userLng;
  final String? customBadge;
  final bool showStoreName;

  ProductCard({
    super.key,
    required this.product,
    VoidCallback? onTap,
    this.onFavoriteTap,
    VoidCallback? onEditTap,
    bool showUnavailableOverlay = false,
    this.showStoreName = true,
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
              _buildLocationText(product, showStoreName, userLat, userLng),
          bottomLeftIcon: Icons.location_on_outlined,
          isUnavailable: !product.isAvailable,
          showUnavailableOverlay: showUnavailableOverlay,
          onTap: (product.isAvailable || onEditTap != null) ? onTap : null,
          onEditTap: onEditTap,
        );

  static String? _buildLocationText(
      Post product, bool showStoreName, double? userLat, double? userLng) {
    if (!showStoreName) return null;

    final dist = Helpers.haversineDistance(
      userLat,
      userLng,
      product.storeLatitude,
      product.storeLongitude,
    );
    if (dist != null) return Helpers.formatDistance(dist);

    if (product.storeAddress.isNotEmpty) return product.storeAddress;
    return null;
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
    final hasStoreName = showStoreName && product.storeName.trim().isNotEmpty;
    final hasBadge = customBadge != null && customBadge!.isNotEmpty;

    if (!hasStoreName && !hasBadge) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasStoreName)
          GestureDetector(
            onTap: () => _navigateToStore(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.storeIsVerified) ...[
                  const Icon(
                    Icons.verified,
                    size: 13,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    product.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (hasStoreName && hasBadge) const SizedBox(height: 6),
        if (hasBadge) _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final badgeText = customBadge!;
    final isUnavailable = badgeText.toLowerCase().contains('not available');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUnavailable
            ? const Color(0xFFFFF2E2).withOpacity(0.8)
            : const Color(0xFFFFF9E6).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        badgeText,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8A4B08),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
