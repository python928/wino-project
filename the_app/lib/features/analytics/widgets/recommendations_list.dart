import 'dart:math' as math;

import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/home_provider.dart';
import '../../../core/providers/post_provider.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/offer_model.dart';
import '../../../data/models/post_model.dart';
import '../../../presentation/common/constants/card_constants.dart';
import '../../../presentation/shared_widgets/cards/pack_card.dart';
import '../../../presentation/shared_widgets/cards/product_card.dart';
import '../../../presentation/shared_widgets/cards/promotion_card.dart';
import '../../../presentation/shared_widgets/cards/store_chip.dart';

/// Recommended for you — top section on home page.
/// Sub-section 1: horizontal mix of ProductCards, PromotionCards, PackCards.
/// Sub-section 2: horizontal compact store chips (category style).
class RecommendationsList extends StatelessWidget {
  final void Function(Post)? onProductTap;
  final void Function(Offer)? onOfferTap;

  const RecommendationsList({
    super.key,
    this.onProductTap,
    this.onOfferTap,
  });

  double _cardWidth(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return (sw -
            CardConstants.gridHorizontalPadding * 2 -
            CardConstants.gridCrossAxisSpacing *
                (CardConstants.gridCrossAxisCount - 1)) /
        CardConstants.gridCrossAxisCount;
  }

  Widget _sectionLabel(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.tr(title),
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PostProvider, HomeProvider>(
      builder: (context, postProvider, homeProvider, _) {
        // Filter products to exclude those with active discounts
        final allProducts = homeProvider.recentProducts;
        final products = allProducts
            .where((p) => !postProvider.isProductDiscounted(p))
            .toList();
        final offers = postProvider.offers;
        final packs = homeProvider.packs;
        final stores = homeProvider.featuredStores; // List<User>
        final userLat = homeProvider.discoveryRadiusKm != null
          ? homeProvider.discoveryUserLat
          : null;
        final userLng = homeProvider.discoveryRadiusKm != null
          ? homeProvider.discoveryUserLng
          : null;
        final showDistance = homeProvider.discoveryRadiusKm != null;

        final hasCards =
            products.isNotEmpty || offers.isNotEmpty || packs.isNotEmpty;
        final hasStores = stores.isNotEmpty;

        // Nothing loaded yet → hide (spinners shown in sections below)
        if (!hasCards && !hasStores) return const SizedBox.shrink();

        // Build interleaved card list: cycle through products → discounts → packs
        final List<Widget> mixedCards = [];
        const maxEach = 6;
        final ps = products.take(maxEach).toList();
        final os = offers.take(maxEach).toList();
        final ks = packs.take(maxEach).toList();
        final loopCount = math.max(ps.length, math.max(os.length, ks.length));

        for (int i = 0; i < loopCount; i++) {
          if (i < ps.length) {
            final p = ps[i];
            mixedCards.add(ProductCard(
              product: p,
              userLat: userLat,
              userLng: userLng,
              onTap: onProductTap != null
                  ? () => onProductTap!(p)
                  : () => Navigator.pushNamed(
                        context,
                        Routes.productDetails,
                        arguments: p,
                      ),
              onFavoriteTap: () {},
            ));
          }
          if (i < os.length) {
            final o = os[i];
            mixedCards.add(PromotionCard(
              offer: o,
              userLat: userLat,
              userLng: userLng,
              onTap: onOfferTap != null ? () => onOfferTap!(o) : null,
            ));
          }
          if (i < ks.length) {
            mixedCards.add(PackCard(
              pack: ks[i],
              userLat: userLat,
              userLng: userLng,
            ));
          }
        }

        final cardWidth = _cardWidth(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('Recommended for you'),
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Sub-section 1: Products · Discounts · Packs ─────────────────
            if (hasCards) ...[
              SizedBox(
                height: 280,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: CardConstants.gridHorizontalPadding),
                  itemCount: mixedCards.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: CardConstants.gridCrossAxisSpacing),
                  itemBuilder: (_, i) =>
                      SizedBox(width: cardWidth, child: mixedCards[i]),
                ),
              ),
            ],

            // ── Sub-section 2: Stores (category-chip style) ─────────────────
            if (hasStores) ...[
              const SizedBox(height: 24),
              _sectionLabel(context, 'Stores'),
              SizedBox(
                height: 136,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: CardConstants.gridHorizontalPadding),
                  itemCount: stores.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => StoreChip.fromUser(
                    store: stores[i],
                    userLat: userLat,
                    userLng: userLng,
                    showDistance: showDistance,
                    onTap: () => Navigator.pushNamed(
                      context,
                      Routes.store,
                      arguments: stores[i].id,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
