import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/card_styles.dart';
import '../../theme/card_dimensions.dart';
import '../../utils/helpers.dart';

/// Unified store card component supporting both vertical and horizontal layouts
/// Provides consistent UI/UX for stores across all screens
class UnifiedStoreCard extends StatelessWidget {
  // Common properties
  final String storeName;
  final String? storeCategory;
  final String? logoUrl;
  final String? coverUrl;
  final VoidCallback? onTap;

  // Stats
  final double? rating;
  final int? followers;
  final int? productsCount;
  final bool isFollowing;

  // Layout
  final bool isHorizontal;
  final bool showCover;

  const UnifiedStoreCard({
    super.key,
    required this.storeName,
    this.storeCategory,
    this.logoUrl,
    this.coverUrl,
    this.onTap,
    this.rating,
    this.followers,
    this.productsCount,
    this.isFollowing = false,
    this.isHorizontal = false,
    this.showCover = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontalCard(context);
    }
    return _buildVerticalCard(context);
  }

  Widget _buildVerticalCard(BuildContext context) {
    return SizedBox(
      width: CardDimensions.storeCardVerticalWidth,
      height: CardDimensions.storeCardVerticalHeight,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: CardStyles.standard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Image
              if (showCover) _buildCoverImage(),

              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(CardDimensions.cardPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo (overlaps cover slightly if cover is shown)
                      if (showCover)
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: _buildStoreLogo(),
                        )
                      else
                        _buildStoreLogo(),

                      // Store name
                      Text(
                        storeName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      // Category
                      if (storeCategory != null)
                        Text(
                          storeCategory!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),

                      // Stats row
                      _buildStatsRow(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: CardDimensions.storeCardHorizontalHeight,
        padding: EdgeInsets.all(CardDimensions.cardPadding),
        decoration: CardStyles.standard(),
        child: Row(
          children: [
            // Logo
            _buildStoreLogo(size: CardDimensions.storeLogoSize),

            SizedBox(width: CardDimensions.cardElementSpacing),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Store name
                  Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  // Category
                  if (storeCategory != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      storeCategory!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Stats row
                  _buildStatsRow(),
                ],
              ),
            ),

            // Follow indicator
            if (isFollowing)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
                size: CardDimensions.iconMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(CardDimensions.cardRadius),
      ),
      child: SizedBox(
        height: 55,
        child: coverUrl != null && coverUrl!.isNotEmpty
            ? Image.network(
                coverUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultCover();
                },
              )
            : _buildDefaultCover(),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      color: AppColors.primaryColor.withOpacity(0.1),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_rounded,
        color: AppColors.primaryColor.withOpacity(0.3),
        size: 32,
      ),
    );
  }

  Widget _buildStoreLogo({double? size}) {
    final logoSize = size ?? 40.0;
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: logoUrl != null && logoUrl!.isNotEmpty
            ? Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultLogo();
                },
              )
            : _buildDefaultLogo(),
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      color: AppColors.primaryColor.withOpacity(0.1),
      alignment: Alignment.center,
      child: Icon(
        Icons.store,
        color: AppColors.primaryColor,
        size: 20,
      ),
    );
  }

  Widget _buildStatsRow() {
    final List<Widget> stats = [];

    // Rating
    if (rating != null) {
      stats.addAll([
        Icon(
          Icons.star,
          size: CardDimensions.iconSmall,
          color: Colors.amber,
        ),
        const SizedBox(width: 2),
        Text(
          rating!.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ]);
    }

    // Followers
    if (followers != null) {
      if (stats.isNotEmpty) {
        stats.add(const SizedBox(width: 8));
      }
      stats.addAll([
        Icon(
          Icons.people_outline,
          size: CardDimensions.iconSmall,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 2),
        Text(
          Helpers.formatNumber(followers!),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ]);
    }

    // Products count
    if (productsCount != null) {
      if (stats.isNotEmpty) {
        stats.add(const SizedBox(width: 8));
      }
      stats.addAll([
        Icon(
          Icons.shopping_bag_outlined,
          size: CardDimensions.iconSmall,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 2),
        Text(
          productsCount.toString(),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ]);
    }

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment:
          isHorizontal ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: stats,
    );
  }
}
