import 'package:flutter/material.dart';
import '../../../core/routing/routes.dart';
import '../../../data/models/offer_model.dart';
import '../../common/widgets/unified_item_card.dart';

/// Unified Promotion Card using UnifiedItemCard
/// Displays promotions/offers consistently across home, search, and discovery screens
class PromotionCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback? onTap;

  const PromotionCard({
    super.key,
    required this.offer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final product = offer.product;

    // Create a modified product with promotion pricing
    final productWithPromotion = product.copyWith(
      price: offer.newPrice,
      oldPrice: product.price,
      discountPercentage: offer.discountPercentage,
    );

    return UnifiedItemCard(
      title: product.title,
      imageUrl: product.image,
      price: offer.newPrice,
      oldPrice: product.price,
      discountPercentage: offer.discountPercentage,
      rating: product.rating,
      bottomLeftText: product.storeName,
      onTap: onTap ?? () {
        Navigator.pushNamed(
          context,
          Routes.productDetails,
          arguments: productWithPromotion,
        );
      },
    );
  }
}
