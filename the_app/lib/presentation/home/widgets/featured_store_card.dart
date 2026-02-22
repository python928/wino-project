import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/card_styles.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/user_model.dart';

/// A card widget for displaying a featured store in horizontal lists
class FeaturedStoreCard extends StatelessWidget {
  final User store;
  final VoidCallback? onTap;

  const FeaturedStoreCard({
    super.key,
    required this.store,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: CardStyles.standard(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 55,
                child: store.coverImage != null && store.coverImage!.isNotEmpty
                    ? Image.network(
                        store.coverImage!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: AppColors.primaryPurple.withValues(alpha: 0.1),
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
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: store.profileImage != null && store.profileImage!.isNotEmpty
                          ? Image.network(
                              store.profileImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar();
                              },
                            )
                          : _buildDefaultAvatar(),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          store.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (store.isVerified) ...[
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.verified,
                          size: 12,
                          color: AppColors.primaryPurple,
                        ),
                      ],
                    ],
                  ),

                  // Category
                  if (store.storeType.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      store.storeType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rating
                      const Icon(Icons.star, size: 11, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        store.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Followers
                      Icon(Icons.people_outline, size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        Helpers.formatLargeNumber(store.followersCount),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.3),
            AppColors.primaryColor.withValues(alpha: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.primaryPurple.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Icon(
        Icons.store,
        color: AppColors.primaryPurple,
        size: 20,
      ),
    );
  }
}

/// A horizontal card for displaying stores in a list
class StoreListCard extends StatelessWidget {
  final User store;
  final VoidCallback? onTap;

  const StoreListCard({
    super.key,
    required this.store,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: CardStyles.standard(),
        child: Row(
          children: [
            // Arrow (for RTL)
            Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppColors.textHint,
            ),

            const Spacer(),

            // Store Info
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Name with verification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (store.isVerified) ...[
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.primaryPurple,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          store.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Category
                  if (store.storeType.isNotEmpty)
                    Text(
                      store.storeType,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Rating
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(
                        ' ${store.averageRating.toStringAsFixed(1)} ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Followers
                      Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                      Text(
                        ' ${Helpers.formatLargeNumber(store.followersCount)} ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      // Location if available
                      if (store.city != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                        Text(
                          ' ${store.city} ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Store Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: store.profileImage != null && store.profileImage!.isNotEmpty
                        ? Image.network(
                            store.profileImage!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const Icon(Icons.store, size: 26, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.primaryPurple.withValues(alpha: 0.1),
                            alignment: Alignment.center,
                            child: Icon(Icons.store, size: 26, color: AppColors.primaryPurple),
                          ),
                  ),
                ),

                // Online Status
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
