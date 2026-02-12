import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

/// Merchant profile header with cover, avatar, store info, and actions
class ProfileMerchantHeader extends StatelessWidget {
  final String userName;
  final String location;
  final String phoneNumber;
  final String storeDescription;
  final String? avatarUrl;
  final String? storeCoverUrl;
  final bool isUploadingImage;
  final bool isUploadingCover;
  final int followersCount;
  final double averageRating;
  final VoidCallback onPickImage;
  final VoidCallback onPickCoverImage;
  final VoidCallback? onSettingsTap;
  final Gradient primaryGradient;

  const ProfileMerchantHeader({
    super.key,
    required this.userName,
    required this.location,
    required this.phoneNumber,
    required this.storeDescription,
    this.avatarUrl,
    this.storeCoverUrl,
    required this.isUploadingImage,
    required this.isUploadingCover,
    required this.followersCount,
    required this.averageRating,
    required this.onPickImage,
    required this.onPickCoverImage,
    this.onSettingsTap,
    required this.primaryGradient,
  });

  @override
  Widget build(BuildContext context) {
    final followersText = Helpers.formatNumber(followersCount);
    final ratingText = Helpers.formatRating(averageRating);
    final hasPhone = phoneNumber.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: AppColors.primaryDeep.withValues(alpha: 0.08)),
              child: (storeCoverUrl != null && storeCoverUrl!.isNotEmpty)
                  ? Image.network(
                      storeCoverUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(gradient: primaryGradient),
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(gradient: primaryGradient)),
                    )
                  : Container(
                      decoration: BoxDecoration(gradient: primaryGradient)),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: onSettingsTap,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_outlined,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
            Positioned(
              bottom: -34,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.grey.shade100,
                  child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl!,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.store,
                                size: 30,
                                color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.store, size: 30, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 46),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 18, color: AppColors.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        followersText,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded,
                          size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        ratingText,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (storeDescription.isNotEmpty)
                Text(
                  storeDescription,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[600], height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (hasPhone) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 18, color: AppColors.primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        phoneNumber,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
