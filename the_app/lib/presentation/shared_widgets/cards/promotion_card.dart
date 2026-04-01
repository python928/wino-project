import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/cards/base_item_card.dart';
import '../../../data/models/offer_model.dart';
import '../../../data/repositories/post_repository.dart';
import '../../product/product_detail_screen.dart';

/// Promotion Card
/// Shows discount/ad badges plus duration.
class PromotionCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final bool showUnavailableOverlay;
  final bool showStoreName;
  final double? userLat;
  final double? userLng;

  const PromotionCard({
    super.key,
    required this.offer,
    this.onTap,
    this.onEditTap,
    this.showUnavailableOverlay = true,
    this.showStoreName = true,
    this.userLat,
    this.userLng,
  });

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
    return _PromotionItemCard(
      offer: offer,
      showUnavailableOverlay: showUnavailableOverlay,
      showStoreName: showStoreName,
      userLat: userLat,
      userLng: userLng,
      onEditTap: onEditTap,
      onTap: onTap ??
          () {
            final productWithPromotion = offer.product.copyWith(
              price: offer.newPrice,
              oldPrice: offer.product.price,
              discountPercentage: offer.discountPercentage,
            );

            if (offer.kind == 'advertising') {
              unawaited(
                PostRepository.registerPromotionClick(
                  offer.id,
                  kind: offer.kind,
                ),
              );
              Navigator.pushNamed(
                context,
                Routes.productDetails,
                arguments: ProductDetailsArgs(
                  product: productWithPromotion,
                  sourceSurface: 'ads',
                  discoveryMode: 'advertising',
                ),
              );
              return;
            }

            Navigator.pushNamed(
              context,
              Routes.productDetails,
              arguments: productWithPromotion,
            );
          },
    );
  }
}

class _PromotionItemCard extends BaseItemCard {
  final Offer offer;

  _PromotionItemCard({
    required this.offer,
    required bool showStoreName,
    required bool showUnavailableOverlay,
    required double? userLat,
    required double? userLng,
    required super.onTap,
    super.onEditTap,
  }) : super(
          title: offer.product.title,
          imageUrl: offer.product.image,
          price: offer.newPrice,
          oldPrice: offer.product.price,
          discountPercentage: offer.discountPercentage,
          customBadge: offer.kind == 'advertising' ? 'Ad' : null,
          rating: offer.product.rating,
          reviewCount: offer.product.reviewCount,
          bottomLeftText: PromotionCard._buildBottomText(
              offer, showStoreName, userLat, userLng),
          bottomLeftIcon: Icons.location_on_outlined,
          // Show "Not available" overlay when the offer/product is unavailable
          // OR when the promotion is out of its start/end window.
          isUnavailable: !(offer.isAvailable &&
              offer.product.isAvailable &&
              offer.isAvailableNow),
          unavailableMessage: _unavailableMessageFor(offer),
          showUnavailableOverlay: showUnavailableOverlay,
        );

  static String _unavailableMessageFor(Offer offer) {
    // Priority (per requirement):
    // - If the promotion is ACTIVE but its duration ended => Expired
    // - If the promotion is explicitly disabled => Not available
    // - Otherwise => Not available
    final now = DateTime.now();
    final end = offer.endDate;
    if (offer.isAvailable && end != null && now.isAfter(end)) {
      return 'Expired';
    }
    if (!offer.isAvailable) return 'Not available';
    return 'Not available';
  }

  @override
  Widget? buildCustomImageOverlay(BuildContext context) {
    // Show duration on image for discounts (promotions) only.
    if (offer.kind == 'advertising') return null;

    final end = offer.endDate;
    if (end == null) return null;

    return Positioned(
      left: AppConstants.spacing8,
      bottom: AppConstants.spacing8,
      right: AppConstants.spacing8,
      child: _LiveDurationBadge(
        start: offer.startDate,
        end: end,
      ),
    );
  }

  @override
  Widget? buildCustomFooterInfo(BuildContext context) {
    final info = <String>[];

    // Duration is shown on the image for discounts.
    if (offer.kind == 'advertising') {
      final durationStr = offer.getDurationString();
      if (durationStr != null && durationStr.isNotEmpty) {
        info.add(durationStr);
      }
    }

    final remaining = offer.remainingImpressions;
    if (remaining != null) info.add('$remaining slots');

    if (info.isEmpty) return null;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: info.map(
        (text) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8A4B08),
              ),
            ),
          );
        },
      ).toList(),
    );
  }
}

class _LiveDurationBadge extends StatelessWidget {
  final DateTime? start;
  final DateTime end;

  const _LiveDurationBadge({
    required this.start,
    required this.end,
  });

  static String _format(Duration duration) {
    var totalSeconds = duration.inSeconds;
    if (totalSeconds < 0) totalSeconds = 0;

    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    if (days > 0) {
      final d = '$days day${days == 1 ? '' : 's'}';
      return '$d $hours:$mm:$ss';
    }
    return '${duration.inHours}:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder is enough here: it updates the badge once/second without
    // manually managing timers.
    return StreamBuilder<DateTime>(
      stream: Stream<DateTime>.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        if (!now.isBefore(end)) {
          // When expired, the card already shows the unavailable overlay.
          return const SizedBox.shrink();
        }

        final remaining = end.difference(now);
        final text = _format(remaining);

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing8,
            vertical: AppConstants.spacing6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusRound),
            gradient: AppColors.purpleGradient,
            boxShadow: AppColors.purpleShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: AppConstants.spacing4),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
