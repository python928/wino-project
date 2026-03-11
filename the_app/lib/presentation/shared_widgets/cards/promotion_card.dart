import 'package:flutter/material.dart';
import '../../../core/routing/routes.dart';
import '../../../data/models/offer_model.dart';
import '../../../core/widgets/cards/base_item_card.dart';
import '../../../core/utils/helpers.dart';

/// Promotion Card inheriting from BaseItemCard
/// Displays promotions/offers with promotional pricing
class PromotionCard extends BaseItemCard {
  final Offer offer;

  PromotionCard({
    super.key,
    required this.offer,
    VoidCallback? onTap,
    VoidCallback? onEditTap,
    bool showUnavailableOverlay = false,
    bool showStoreName = true,
    double? userLat,
    double? userLng,
  }) : super(
          title: offer.product.title,
          imageUrl: offer.product.image,
          price: offer.newPrice,
          oldPrice: offer.product.price,
          discountPercentage: offer.discountPercentage,
          customBadge: offer.isNearEnding ? 'Ending Soon' : null,
          rating: offer.product.rating,
          reviewCount: offer.product.reviewCount,
          bottomLeftText:
              _buildBottomText(offer, showStoreName, userLat, userLng),
          bottomLeftIcon: Icons.location_on_outlined,
          isUnavailable: !(offer.isAvailable && offer.product.isAvailable),
          showUnavailableOverlay: showUnavailableOverlay,
          onTap: onTap,
          onEditTap: onEditTap,
        );

  static String _formatTimeLeft(DateTime? endDate) {
    if (endDate == null) return '';
    final diff = endDate.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays >= 1) return '${diff.inDays}d left';
    if (diff.inHours >= 1) return '${diff.inHours}h left';
    return '${diff.inMinutes.clamp(1, 59)}m left';
  }

  @override
  Widget? buildCustomBottomInfo(BuildContext context) {
    final info = <String>[];
    final timeLeft = _formatTimeLeft(offer.endDate);
    if (timeLeft.isNotEmpty) info.add(timeLeft);
    final remaining = offer.remainingImpressions;
    if (remaining != null) info.add('$remaining slots');
    if (info.isEmpty) return null;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: info
          .map(
            (text) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A4B08),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static String? _buildBottomText(
      Offer offer, bool showStoreName, double? userLat, double? userLng) {
    if (!showStoreName) return null;
    final dist = Helpers.haversineDistance(
      userLat,
      userLng,
      offer.product.storeLatitude,
      offer.product.storeLongitude,
    );
    if (dist != null) return Helpers.formatDistance(dist);
    if (offer.product.storeAddress.isNotEmpty) {
      return offer.product.storeAddress;
    }
    return offer.product.storeName;
  }

  @override
  Widget build(BuildContext context) {
    return BaseItemCard(
      title: title,
      imageUrl: imageUrl,
      price: price,
      oldPrice: oldPrice,
      discountPercentage: discountPercentage,
      rating: rating,
      reviewCount: reviewCount,
      bottomLeftText: bottomLeftText,
      isUnavailable: isUnavailable,
      showUnavailableOverlay: showUnavailableOverlay,
      onTap: onTap ??
          () {
            // Create a modified product with promotion pricing
            final productWithPromotion = offer.product.copyWith(
              price: offer.newPrice,
              oldPrice: offer.product.price,
              discountPercentage: offer.discountPercentage,
            );

            Navigator.pushNamed(
              context,
              Routes.productDetails,
              arguments: productWithPromotion,
            );
          },
      onEditTap: onEditTap,
    );
  }
}
