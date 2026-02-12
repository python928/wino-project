import 'package:flutter/material.dart';
import '../../../core/routing/routes.dart';
import '../../../data/models/offer_model.dart';
import '../../../core/widgets/cards/base_item_card.dart';

/// Promotion Card inheriting from BaseItemCard
/// Displays promotions/offers with promotional pricing
class PromotionCard extends BaseItemCard {
  final Offer offer;

  PromotionCard({
    super.key,
    required this.offer,
    VoidCallback? onTap,
    VoidCallback? onEditTap,
  }) : super(
          title: offer.product.title,
          imageUrl: offer.product.image,
          price: offer.newPrice,
          oldPrice: offer.product.price,
          discountPercentage: offer.discountPercentage,
          rating: offer.product.rating,
          bottomLeftText: offer.product.storeName,
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
      bottomLeftText: bottomLeftText,
      onTap: onTap ?? () {
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
