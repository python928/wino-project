import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../shared_widgets/contact_action_row.dart';

/// Profile header with cover, avatar, store info, and actions
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
  final VoidCallback? onDeleteImage;
  final VoidCallback? onDeleteCoverImage;
  final VoidCallback? onSettingsTap;
  final Function(String)? onSettingsMenuSelected;
  final bool isOwnerView;
  final bool isFollowing;
  final VoidCallback? onFollowTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onReportTap;
  final Gradient primaryGradient;

  // Social Links
  final String? facebook;
  final String? instagram;
  final String? whatsapp;
  final String? tiktok;
  final String? youtube;

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
    this.onDeleteImage,
    this.onDeleteCoverImage,
    this.onSettingsTap,
    this.onSettingsMenuSelected,
    required this.isOwnerView,
    this.isFollowing = false,
    this.onFollowTap,
    this.onFavoriteTap,
    this.onReportTap,
    required this.primaryGradient,
    this.facebook,
    this.instagram,
    this.whatsapp,
    this.tiktok,
    this.youtube,
  });

  @override
  Widget build(BuildContext context) {
    final followersText = Helpers.formatNumber(followersCount);
    final ratingText = Helpers.formatRating(averageRating);
    final displayPhone = _formatLocalPhone(phoneNumber);
    final hasPhone = displayPhone.isNotEmpty;

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
              child: onSettingsMenuSelected == null
                  ? const SizedBox.shrink()
                  : PopupMenuButton<String>(
                      onSelected: onSettingsMenuSelected!,
                      offset: const Offset(-10, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      elevation: 8,
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  color: AppColors.primaryColor, size: 20),
                              const SizedBox(width: 12),
                              const Text('Edit Information'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(Icons.logout,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              const Text('Logout',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
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
                      radius: 40,
                      backgroundColor: Colors.grey.shade100,
                      child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                avatarUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.store,
                                    size: 30,
                                    color: Colors.grey),
                              ),
                            )
                          : const Icon(Icons.store,
                              size: 30, color: Colors.grey),
                    ),
                  ),
                ],
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
              const SizedBox(height: 6),
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

              // Follow and Favorite buttons for non-owner view
              if (!isOwnerView) ...[
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onFollowTap,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isFollowing ? Icons.done : Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                isFollowing ? 'Following' : 'Follow',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onReportTap,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined,
                                size: 16, color: Colors.red.shade500),
                            const SizedBox(width: 6),
                            Text(
                              'Report',
                              style: TextStyle(
                                color: Colors.red.shade500,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (!isOwnerView) ...[
                const SizedBox(height: 10),
                ContactActionRow(
                  phone: hasPhone ? phoneNumber : null,
                  whatsapp: whatsapp,
                  buttonVerticalPadding: 10,
                ),
              ],

              // Social Icons Row
              if (_hasAnySocial) ...[
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (facebook?.isNotEmpty == true)
                        _buildSocialIcon(FontAwesomeIcons.facebook, facebook!,
                            Colors.blue[800]!),
                      if (instagram?.isNotEmpty == true)
                        _buildSocialIcon(FontAwesomeIcons.instagram, instagram!,
                            Colors.pink),
                      if (tiktok?.isNotEmpty == true)
                        _buildSocialIcon(
                            FontAwesomeIcons.tiktok, tiktok!, Colors.black),
                      if (youtube?.isNotEmpty == true)
                        _buildSocialIcon(
                            FontAwesomeIcons.youtube, youtube!, Colors.red),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  bool get _hasAnySocial =>
      (facebook?.isNotEmpty == true) ||
      (instagram?.isNotEmpty == true) ||
      (tiktok?.isNotEmpty == true) ||
      (youtube?.isNotEmpty == true);

  String _formatLocalPhone(String raw) {
    final compact = raw.replaceAll(' ', '').trim();
    if (compact.isEmpty) return '';
    if (compact.startsWith('+213')) {
      final local = compact.substring(4);
      if (local.isEmpty) return '';
      return local.startsWith('0') ? local : '0$local';
    }
    if (compact.startsWith('213')) {
      final local = compact.substring(3);
      if (local.isEmpty) return '';
      return local.startsWith('0') ? local : '0$local';
    }
    return compact;
  }

  Widget _buildSocialIcon(IconData icon, String url, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => Helpers.launchURL(url),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: FaIcon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool compact = false,
  }) {
    final size = compact ? 28.0 : 36.0;
    final iconSize = compact ? 16.0 : 19.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }
}
