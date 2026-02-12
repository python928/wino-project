import 'package:flutter/material.dart';
import '../../../core/routing/routes.dart';
import '../../../data/models/offer_model.dart';
import '../../../core/widgets/cards/base_item_card.dart';

/// Promotion Card inheriting from BaseItemCard
/// Displays promotions/offers with promotional pricing
class PromotionCard extends BaseItemCard {
  final Offer offer;
  final bool showUnavailableOverlay;
  final bool showStoreName;

  PromotionCard({
    super.key,
    required this.offer,
    VoidCallback? onTap,
    VoidCallback? onEditTap,
    this.showUnavailableOverlay = false,
    this.showStoreName = true,
  }) : super(
          title: offer.product.title,
          imageUrl: offer.product.image,
          price: offer.newPrice,
          oldPrice: offer.product.price,
          discountPercentage: offer.discountPercentage,
          rating: offer.product.rating,
          reviewCount: offer.product.reviewCount,
          bottomLeftText: showStoreName ? offer.product.storeName : null,
          isUnavailable: !(offer.isAvailable && offer.product.isAvailable),
          showUnavailableOverlay: showUnavailableOverlay,
          onTap: onTap,
          onEditTap: onEditTap,
        );

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
