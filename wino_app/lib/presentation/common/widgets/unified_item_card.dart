import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/card_styles.dart';
import '../../../core/components/skeleton_loader.dart';
import '../../../core/utils/helpers.dart';

/// Unified card component for Products, Promotions, and Packs
/// Provides consistent UI/UX across all item types
/// Updated with lib design system (purple theme, 12px radius)
class UnifiedItemCard extends StatelessWidget {
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
  final String? bottomLeftText; // For store name or product count
  final IconData? bottomLeftIcon;
  final VoidCallback? onBottomLeftTap; // Tap handler for store name/bottom left text

  // Special cases
  final Widget? customImageWidget; // For pack stacked images
  final bool isUnavailable;

  const UnifiedItemCard({
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
    this.bottomLeftText,
    this.bottomLeftIcon,
    this.onBottomLeftTap,
    this.customImageWidget,
    this.isUnavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnavailable ? null : onTap,
      child: Container(
        decoration: CardStyles.standard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            _buildImageSection(),

            // Content Section
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Flexible(
                      child: _buildTitle(),
                    ),

                    // Price and Bottom row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Price or custom info
                        if (hidePrice)
                          _buildCallForPrice()
                        else if (price != null)
                          _buildPriceRow(),

                        const SizedBox(height: AppConstants.spacing4),

                        // Bottom row: Rating + Additional info
                        _buildBottomRow(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Image or Custom Widget
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.cardRadius),  // Match card radius
          ),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: customImageWidget ?? _buildStandardImage(),
          ),
        ),

        // Discount Badge
        if (discountPercentage != null || customBadge != null)
          Positioned(
            top: AppConstants.spacing8,
            left: AppConstants.spacing8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing8,
                vertical: AppConstants.spacing4,
              ),
              decoration: AppDecorations.discountBadge(),  // Using lib design
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

        // Unavailable Overlay
        if (isUnavailable)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.cardRadius)),
              ),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing12, vertical: AppConstants.spacing6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: const Text(
                  'Unavailable',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: AppConstants.fontSizeCaption,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStandardImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: Colors.grey[100],
        alignment: Alignment.center,
        child: const Icon(Icons.image, size: AppConstants.iconXL, color: Colors.grey),
      );
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        // Use skeleton loader (lib design system)
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
          child: const Icon(Icons.broken_image, size: AppConstants.iconXL, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: AppConstants.fontSizeCaption,
        height: 1.2,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCallForPrice() {
    return Row(
      children: [
        Icon(Icons.phone_outlined, size: AppConstants.fontSizeCaption, color: AppColors.primary),
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
              fontWeight: FontWeight.bold,
              fontSize: AppConstants.fontSizeBody,
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

  Widget _buildBottomRow() {
    return Row(
      children: [
        // Rating
        if (rating != null) ...[
          const Icon(Icons.star, size: AppConstants.fontSizeCaption, color: Colors.amber),
          const SizedBox(width: AppConstants.spacing4),
          Text(
            rating!.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: AppConstants.fontSizeSmall,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        // Separator
        if (rating != null && bottomLeftText != null)
          const SizedBox(width: AppConstants.spacing6),

        // Additional info (store name, product count, etc.)
        if (bottomLeftText != null)
          Expanded(
            child: GestureDetector(
              onTap: onBottomLeftTap,
              child: Row(
                children: [
                  if (bottomLeftIcon != null) ...[
                    Icon(bottomLeftIcon, size: AppConstants.fontSizeSmall, color: Colors.grey[600]),
                    const SizedBox(width: AppConstants.spacing4),
                  ],
                  Expanded(
                    child: Text(
                      bottomLeftText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: bottomLeftIcon != null
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: AppConstants.fontSizeSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
