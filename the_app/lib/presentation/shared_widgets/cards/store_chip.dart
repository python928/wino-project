import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

/// Category-style store chip: circle avatar · name · rating · followers.
/// Used on home (featured stores) and search (stores results).
class StoreChip extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double rating;
  final int followersCount;
  final bool isVerified;
  final VoidCallback? onTap;

  const StoreChip({
    super.key,
    this.imageUrl,
    required this.name,
    required this.rating,
    required this.followersCount,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Circle avatar ──────────────────────────────────────────────
            SizedBox(
              width: 74,
              height: 74,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      width: 70,
                      height: 70,
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

            const SizedBox(height: 6),

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
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 3),

            // ── Rating + Followers ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.people_outline_rounded,
                    size: 11, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text(
                  Helpers.formatLargeNumber(followersCount),
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
