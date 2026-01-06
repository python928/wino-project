import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

/// Unified card component for Products, Promotions, and Packs
/// Provides consistent UI/UX across all item types
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            _buildImageSection(),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
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

                        const SizedBox(height: 4),

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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: customImageWidget ?? _buildStandardImage(),
          ),
        ),

        // Discount Badge
        if (discountPercentage != null || customBadge != null)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                customBadge ?? '-$discountPercentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Edit Button
        if (onEditTap != null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  size: 16,
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Unavailable',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
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
        fontSize: 13,
        height: 1.2,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCallForPrice() {
    return Row(
      children: [
        Icon(Icons.phone_outlined, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          'Call for price',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
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
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (oldPrice != null && oldPrice! > price!) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              Helpers.formatPrice(oldPrice!),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
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
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 3),
          Text(
            rating!.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        // Separator
        if (rating != null && bottomLeftText != null)
          const SizedBox(width: 6),

        // Additional info (store name, product count, etc.)
        if (bottomLeftText != null)
          Expanded(
            child: GestureDetector(
              onTap: onBottomLeftTap,
              child: Row(
                children: [
                  if (bottomLeftIcon != null) ...[
                    Icon(bottomLeftIcon, size: 11, color: Colors.grey[600]),
                    const SizedBox(width: 3),
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
                        fontSize: 11,
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
