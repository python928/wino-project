import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../components/skeleton_loader.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../theme/app_decorations.dart';
import '../../theme/card_dimensions.dart';
import '../../theme/card_styles.dart';
import '../../utils/helpers.dart';

/// Specialized base class for item cards (products, packs, promotions)
/// Provides consistent UI/UX and standardized dimensions
/// All item cards should inherit from this instead of creating custom layouts
class BaseItemCard extends StatelessWidget {
  // Common properties
  final String title;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;

  // Price properties
  final double? price;
  final double? oldPrice;
  final bool hidePrice;

  // Badge properties
  final int? discountPercentage;
  final String? customBadge;

  // Bottom info properties
  final double? rating;
  final int? reviewCount;
  final String? bottomLeftText;
  final IconData? bottomLeftIcon;
  final VoidCallback? onBottomLeftTap;

  // Custom widget properties
  final Widget? customImageWidget;
  final bool isUnavailable;
  final bool showUnavailableOverlay;
  final String unavailableMessage;

  const BaseItemCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.onTap,
    this.onEditTap,
    this.price,
    this.oldPrice,
    this.hidePrice = false,
    this.discountPercentage,
    this.customBadge,
    this.rating,
    this.reviewCount,
    this.bottomLeftText,
    this.bottomLeftIcon,
    this.onBottomLeftTap,
    this.customImageWidget,
    this.isUnavailable = false,
    this.showUnavailableOverlay = false,
    this.unavailableMessage = 'Not available',
  });

  bool _isLikelyArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Build custom content - override this method for specialized behavior
  /// By default returns null to use standard layout
  Widget? buildCustomContent(BuildContext context) => null;

  /// Build custom image widget - override to customize image display
  Widget? buildCustomImageWidget(BuildContext context) => customImageWidget;

  /// Build custom widgets to overlay on top of the image section.
  /// Return a widget meant to live inside the image Stack (can be Positioned).
  Widget? buildCustomImageOverlay(BuildContext context) => null;

  /// Build custom bottom info - override to add specialized bottom content
  Widget? buildCustomBottomInfo(BuildContext context) => null;

  /// Build custom footer info shown near the bottom of the card, above price.
  Widget? buildCustomFooterInfo(BuildContext context) => null;

  /// Override when a card should hide the default meta row under the title.
  bool replaceDefaultMetaSection(BuildContext context) => false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : CardDimensions.itemCardWidth;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : CardDimensions.itemCardHeight;
        final customBottomInfo = buildCustomBottomInfo(context);
        final customFooterInfo = buildCustomFooterInfo(context);
        final showPriceRow = hidePrice || price != null;

        final contentPadding = width < 100 ? 6.0 : CardDimensions.cardPadding;

        // Make the card responsive to very short tiles.
        // Some grids use a larger childAspectRatio (shorter height), which can
        // leave too little space for title/meta/price and cause RenderFlex
        // overflows inside the content Column.
        final estimatedTitleHeight = width < 120 ? 18.0 : 34.0; // 1–2 lines
        final estimatedMetaHeight = (rating != null ? 16.0 : 0.0) +
            (bottomLeftText != null ? 16.0 : 0.0);
        final estimatedMetaGap =
            (rating != null && bottomLeftText != null) ? 6.0 : 0.0;
        final estimatedPriceHeight =
            hidePrice ? 18.0 : (price != null ? 22.0 : 0.0);
        final estimatedCustomBottomHeight =
            customBottomInfo != null && !replaceDefaultMetaSection(context)
                ? 22.0 + AppConstants.spacing6
                : 0.0;
        final estimatedFooterHeight = customFooterInfo != null
            ? 24.0 + (showPriceRow ? AppConstants.spacing6 : 0.0)
            : 0.0;
        final estimatedContentMinHeight = (contentPadding * 2) +
            estimatedTitleHeight +
            AppConstants.spacing8 +
            estimatedMetaHeight +
            estimatedMetaGap +
            estimatedCustomBottomHeight +
            estimatedFooterHeight +
            (estimatedPriceHeight > 0 ? AppConstants.spacing6 : 0.0) +
            estimatedPriceHeight;

        // Keep the image square when there's enough height; otherwise shrink
        // it to guarantee content fits.
        final imageHeight = math.min(
          width,
          math.max(0.0, height - estimatedContentMinHeight),
        );

        return SizedBox(
          width: width,
          height: height,
          child: GestureDetector(
            onTap: isUnavailable ? null : onTap,
            child: Container(
              decoration: CardStyles.standard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: _buildImageSection(context),
                  ),

                  // Content Section
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(contentPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildCustomContent(context) ?? _buildTitle(),
                          const SizedBox(height: AppConstants.spacing8),
                          if (replaceDefaultMetaSection(context))
                            (customBottomInfo ?? const SizedBox.shrink())
                          else ...[
                            _buildMetaSection(),
                            if (customBottomInfo != null)
                              const SizedBox(height: AppConstants.spacing6),
                            if (customBottomInfo != null) customBottomInfo,
                          ],
                          const Spacer(),
                          if (customFooterInfo != null) customFooterInfo,
                          if (customFooterInfo != null && showPriceRow)
                            const SizedBox(height: AppConstants.spacing6),
                          if (hidePrice)
                            _buildCallForPrice()
                          else if (price != null)
                            _buildPriceRow(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final showUnavailable = isUnavailable && showUnavailableOverlay;
    final customOverlay = buildCustomImageOverlay(context);

    return Stack(
      children: [
        // Image or Custom Widget
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.cardRadius),
          ),
          child: Opacity(
            opacity: showUnavailable ? 0.45 : 1.0,
            child: SizedBox.expand(
              child: buildCustomImageWidget(context) ?? _buildStandardImage(),
            ),
          ),
        ),

        // Badge (discount / pack)
        if (discountPercentage != null || customBadge != null)
          Positioned(
            top: AppConstants.spacing8,
            left: AppConstants.spacing8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing8,
                vertical: AppConstants.spacing4,
              ),
              decoration: _buildBadgeDecoration(),
              child: Text(
                customBadge ?? '-$discountPercentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppConstants.fontSizeSmall,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Edit Button
        if (onEditTap != null)
          Positioned(
            top: AppConstants.spacing8,
            right: AppConstants.spacing8,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacing6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: AppConstants.spacing6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  size: AppConstants.iconSmall,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

        if (customOverlay != null) customOverlay,

        // Unavailable Overlay (opt-in per screen)
        if (showUnavailable)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.18),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppConstants.cardRadius)),
                ),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacing16,
                    vertical: AppConstants.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusRound),
                  ),
                  child: Text(
                    unavailableMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: AppConstants.fontSizeBody,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  BoxDecoration _buildBadgeDecoration() {
    final badgeText = (customBadge ?? '').trim().toLowerCase();
    final isPackBadge = badgeText.startsWith('pack');

    if (isPackBadge) {
      return BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
      );
    }

    return AppDecorations.discountBadge();
  }

  Widget _buildStandardImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: Colors.grey[100],
        alignment: Alignment.center,
        child: const Icon(Icons.image,
            size: AppConstants.iconXL, color: Colors.grey),
      );
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Skeleton(
          height: double.infinity,
          width: double.infinity,
          radius: 0,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image,
              size: AppConstants.iconXL, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildTitle() {
    final isRtl = _isLikelyArabic(title);
    return Text(
      title,
      maxLines: 1, // was 2 – avoid overflow when grid tiles are short
      overflow: TextOverflow.ellipsis,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      textAlign: TextAlign.start,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: AppConstants.fontSizeSubtitle,
        height: 1.25,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCallForPrice() {
    return Row(
      children: [
        Icon(Icons.phone_outlined,
            size: AppConstants.fontSizeCaption, color: AppColors.primary),
        const SizedBox(width: AppConstants.spacing4),
        Text(
          'Call for price',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: AppConstants.fontSizeCaption,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      children: [
        Flexible(
          child: Text(
            Helpers.formatPrice(price!),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: AppConstants.fontSizeSubtitle,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (oldPrice != null && oldPrice! > price!) ...[
          const SizedBox(width: AppConstants.spacing6),
          Flexible(
            child: Text(
              Helpers.formatPrice(oldPrice!),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: AppConstants.fontSizeSmall,
                decoration: TextDecoration.lineThrough,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rating != null) _buildRatingRow(),
        if (rating != null && bottomLeftText != null)
          const SizedBox(height: AppConstants.spacing6),
        if (bottomLeftText != null)
          GestureDetector(
            onTap: onBottomLeftTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bottomLeftIcon != null) ...[
                  Icon(bottomLeftIcon,
                      size: AppConstants.fontSizeCaption,
                      color: AppColors.textSecondary),
                  const SizedBox(width: AppConstants.spacing4),
                ],
                Flexible(
                  child: Text(
                    bottomLeftText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: _isLikelyArabic(bottomLeftText!)
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: AppConstants.fontSizeBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRatingRow() {
    final value = (rating ?? 0).clamp(0.0, 5.0);
    final fullStars = value.floor();
    final hasHalfStar = (value - fullStars) >= 0.5;

    return Row(
      children: [
        for (int i = 0; i < 5; i++)
          Icon(
            i < fullStars
                ? Icons.star
                : (i == fullStars && hasHalfStar)
                    ? Icons.star_half
                    : Icons.star_border,
            size: AppConstants.fontSizeSubtitle,
            color: Colors.amber,
          ),
        const SizedBox(width: AppConstants.spacing8),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppConstants.fontSizeBody,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: AppConstants.spacing6),
          Text(
            '(${reviewCount!})',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppConstants.fontSizeBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
