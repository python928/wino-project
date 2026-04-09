import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/user_model.dart';

/// Category-style store chip: circle avatar · name · rating · followers.
/// Used on home (featured stores) and search (stores results).
class StoreChip extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double rating;
  final int followersCount;
  final bool isVerified;
  final String? distanceText;
  final VoidCallback? onTap;

  const StoreChip({
    super.key,
    this.imageUrl,
    required this.name,
    required this.rating,
    required this.followersCount,
    this.isVerified = false,
    this.distanceText,
    this.onTap,
  });

  factory StoreChip.fromUser({
    Key? key,
    required User store,
    double? userLat,
    double? userLng,
    bool showDistance = false,
    VoidCallback? onTap,
  }) {
    String? distanceText;
    if (showDistance) {
      final computedDistance = Helpers.haversineDistance(
        userLat,
        userLng,
        store.latitude,
        store.longitude,
      );
      if (computedDistance != null) {
        distanceText = Helpers.formatDistance(computedDistance);
      } else if (store.distance != null) {
        distanceText = Helpers.formatDistance(store.distance!);
      }
    }

    return StoreChip(
      key: key,
      imageUrl: store.profileImage,
      name: store.fullName,
      rating: store.averageRating,
      followersCount: store.followersCount,
      isVerified: store.isVerified,
      distanceText: distanceText,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDistance = distanceText != null && distanceText!.isNotEmpty;
    final avatarBoxSize = hasDistance ? 70.0 : 74.0;
    final avatarSize = hasDistance ? 66.0 : 70.0;
    final spaceAfterAvatar = hasDistance ? 4.0 : 6.0;
    final spaceAfterName = hasDistance ? 2.0 : 3.0;
    final spaceBeforeDistance = hasDistance ? 2.0 : 3.0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Circle avatar ──────────────────────────────────────────────
            SizedBox(
              width: avatarBoxSize,
              height: avatarBoxSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor.withOpacity(0.08),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: imageUrl != null && imageUrl!.isNotEmpty
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _defaultAvatar(),
                              )
                            : _defaultAvatar(),
                      ),
                    ),
                  ),
                  if (isVerified)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(1),
                        child: const Icon(
                          Icons.verified,
                          size: 17,
                          color: Color(0xFF1DA1F2),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: spaceAfterAvatar),

            // ── Store name ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isVerified) ...[
                  const Icon(
                    Icons.verified,
                    size: 13,
                    color: Color(0xFF1DA1F2),
                  ),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: spaceAfterName),

            // ── Rating + Followers ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.people_outline_rounded,
                    size: 11, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    Helpers.formatLargeNumber(followersCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (distanceText != null) ...[
              SizedBox(height: spaceBeforeDistance),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 11,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      distanceText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.primaryColor.withOpacity(0.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.store_rounded,
        color: AppColors.primaryColor,
        size: 28,
      ),
    );
  }
}
