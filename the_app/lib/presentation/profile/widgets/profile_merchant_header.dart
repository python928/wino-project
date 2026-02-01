import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/providers/post_provider.dart';
import 'profile_stats_card.dart';
import 'profile_action_buttons.dart';

/// Merchant profile header with cover, avatar, store info, and actions
class ProfileMerchantHeader extends StatelessWidget {
  final String userName;
  final String location;
  final String storeDescription;
  final String? avatarUrl;
  final String? storeCoverUrl;
  final bool isUploadingImage;
  final bool isUploadingCover;
  final int followersCount;
  final double averageRating;
  final VoidCallback onPickImage;
  final VoidCallback onPickCoverImage;
  final VoidCallback onSettingsTap;
  final Function(String) onPostMenuSelection;
  final Gradient primaryGradient;

  const ProfileMerchantHeader({
    super.key,
    required this.userName,
    required this.location,
    required this.storeDescription,
    this.avatarUrl,
    this.storeCoverUrl,
    required this.isUploadingImage,
    required this.isUploadingCover,
    required this.followersCount,
    required this.averageRating,
    required this.onPickImage,
    required this.onPickCoverImage,
    required this.onSettingsTap,
    required this.onPostMenuSelection,
    required this.primaryGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final productCount = postProvider.myPosts.length;

        return Column(
          children: [
            // Cover Image Section
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover Image
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeep.withValues(alpha: 0.1),
                  ),
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
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(gradient: primaryGradient),
                            );
                          },
                        )
                      : Container(decoration: BoxDecoration(gradient: primaryGradient)),
                ),
                // Camera icon on cover (top-right)
                Positioned(
                  top: 40,
                  right: 16,
                  child: GestureDetector(
                    onTap: isUploadingCover ? null : onPickCoverImage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: isUploadingCover
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
                // Avatar positioned at bottom-center of cover
                Positioned(
                  bottom: -50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: isUploadingImage ? null : onPickImage,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade100,
                              child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        avatarUrl!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.store,
                                          size: 45,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.store, size: 45, color: Colors.grey),
                            ),
                          ),
                          // Camera icon for avatar
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: isUploadingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: AppColors.primaryColor,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Store name centered under avatar
            Text(
              userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Location - clickable link
            GestureDetector(
              onTap: () {
                // TODO: Open map or location screen
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryColor,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Store description
            if (storeDescription.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  storeDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: AppConstants.spacing16),

            // Settings icon button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onSettingsTap,
                icon: Icon(Icons.settings_outlined, color: Colors.grey[700]),
                tooltip: 'Settings',
              ),
            ),

            const SizedBox(height: 20),

            // Stats Row
            ProfileStatsCard(
              followersCount: followersCount,
              averageRating: averageRating,
              productsCount: productCount,
            ),

            const SizedBox(height: AppConstants.spacing16),

            // Action Buttons
            ProfileActionButtons(
              onPostMenuSelection: onPostMenuSelection,
            ),

            const SizedBox(height: AppConstants.spacing16),
          ],
        );
      },
    );
  }
}
