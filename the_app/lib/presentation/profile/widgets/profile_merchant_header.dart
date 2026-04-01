import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../shared_widgets/app_dropdown_menu.dart';
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
  final bool isVerified;
  final bool isFollowing;
  final VoidCallback? onFollowTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onReportTap;
  final Gradient primaryGradient;
  final Widget? directionsButton;
  final List<AppDropdownAction<String>> settingsActions;
  final bool showImageEditActions;
  final bool showCoverSettingsAction;

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
    this.isVerified = false,
    this.isFollowing = false,
    this.onFollowTap,
    this.onFavoriteTap,
    this.onReportTap,
    required this.primaryGradient,
    this.directionsButton,
    this.settingsActions = const [],
    this.showImageEditActions = true,
    this.showCoverSettingsAction = true,
    this.facebook,
    this.instagram,
    this.whatsapp,
    this.tiktok,
    this.youtube,
  });

  String _localizedLocation(BuildContext context, String raw) {
    if (raw.trim().isEmpty || raw.trim() == '/') return raw;
    final parts = raw
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map(context.tr)
        .toList();
    return parts.isEmpty ? context.tr(raw) : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final followersText = Helpers.formatNumber(followersCount);
    final ratingText = Helpers.formatRating(averageRating);
    final displayPhone = _formatLocalPhone(phoneNumber);
    final hasPhone = displayPhone.isNotEmpty;
    final localizedLoc = _localizedLocation(context, location);
    final showCoverUploadAction = isOwnerView && showImageEditActions;
    final showCoverSettingsMenu = isOwnerView &&
        showCoverSettingsAction &&
        onSettingsMenuSelected != null;
    final showAnyCoverActions = showCoverUploadAction || showCoverSettingsMenu;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cover + Avatar ──────────────────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover image
            SizedBox(
              height: 200,
              width: double.infinity,
              child: (storeCoverUrl != null && storeCoverUrl!.isNotEmpty)
                  ? Image.network(
                      storeCoverUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                            decoration:
                                BoxDecoration(gradient: primaryGradient));
                      },
                      errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(gradient: primaryGradient)),
                    )
                  : Container(
                      decoration: BoxDecoration(gradient: primaryGradient)),
            ),
            // Subtle bottom fade on cover
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Settings / upload buttons
            if (showAnyCoverActions) ...[
              PositionedDirectional(
                top: 14,
                end: 14,
                child: Row(
                  children: [
                    if (showCoverUploadAction)
                      _buildCoverAction(
                        icon: Icons.photo_camera_outlined,
                        onTap: onPickCoverImage,
                      ),
                    if (showCoverSettingsMenu) ...[
                      if (showCoverUploadAction) const SizedBox(width: 8),
                      AppDropdownMenuButton<String>(
                        onSelected: onSettingsMenuSelected!,
                        offset: const Offset(-10, 40),
                        actions: settingsActions.isNotEmpty
                            ? settingsActions
                            : [
                                AppDropdownAction(
                                  value: 'edit',
                                  icon: Icons.edit_outlined,
                                  label: context.tr('Edit Information'),
                                ),
                                AppDropdownAction(
                                  value: 'logout',
                                  icon: Icons.logout,
                                  label: context.tr('Logout'),
                                  destructive: true,
                                  showDividerAbove: true,
                                ),
                              ],
                        child: _buildCoverAction(
                            icon: Icons.settings_outlined, onTap: null),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            // Avatar — positioned to overlap cover bottom
            PositionedDirectional(
              bottom: -40,
              start: 20,
              child: GestureDetector(
                onTap: isOwnerView && showImageEditActions ? onPickImage : null,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.grey.shade100,
                        child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                            ? ClipOval(
                                child: Image.network(
                                  avatarUrl!,
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.store,
                                      size: 28,
                                      color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.store,
                                size: 28, color: Colors.grey),
                      ),
                    ),
                    if (isOwnerView && showImageEditActions)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 13, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Info area below cover ────────────────────────────────────────
        const SizedBox(height: 52),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + verified + stats on same row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, size: 18, color: Colors.blue),
                  ],
                  const Spacer(),
                  _buildInlineStat(
                    icon: Icons.star_rounded,
                    value: ratingText,
                    iconColor: const Color(0xFFB26A00),
                    bg: const Color(0xFFFFF3D6),
                  ),
                  const SizedBox(width: 8),
                  _buildInlineStat(
                    icon: Icons.people_outline_rounded,
                    value: followersText,
                    iconColor: AppColors.primaryColor,
                    bg: AppColors.primaryColor.withOpacity(0.08),
                  ),
                ],
              ),
              // Location (inline, no box)
              if (localizedLoc.isNotEmpty && localizedLoc.trim() != '/') ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        localizedLoc,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              // Description
              if (storeDescription.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  storeDescription,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[600], height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              // Action buttons
              if (!isOwnerView) ...[
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onFollowTap,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 42,
                          decoration: BoxDecoration(
                            color: isFollowing
                                ? AppColors.primaryColor.withOpacity(0.08)
                                : AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            border: isFollowing
                                ? Border.all(
                                    color: AppColors.primaryColor, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isFollowing
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                color: isFollowing
                                    ? AppColors.primaryColor
                                    : Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isFollowing
                                    ? context.tr('Following')
                                    : context.tr('Follow'),
                                style: TextStyle(
                                  color: isFollowing
                                      ? AppColors.primaryColor
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (onReportTap != null) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onReportTap,
                        child: Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.flag_outlined,
                              size: 18, color: Colors.red.shade400),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                ContactActionRow(
                  phone: hasPhone ? phoneNumber : null,
                  whatsapp: whatsapp,
                  trailingAction: directionsButton,
                  buttonVerticalPadding: 10,
                ),
              ],
              // Social icons
              if (_hasAnySocial) ...[
                const SizedBox(height: 14),
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
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInlineStat({
    required IconData icon,
    required String value,
    required Color iconColor,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: iconColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: iconColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverAction({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
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
      padding: const EdgeInsetsDirectional.only(end: 12),
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
}
