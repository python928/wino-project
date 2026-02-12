import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';

/// User profile header with avatar, name, and location
class ProfileUserHeader extends StatelessWidget {
  final String userName;
  final String location;
  final String? avatarUrl;
  final bool isUploadingImage;
  final VoidCallback onPickImage;
  final Color primaryColor;

  const ProfileUserHeader({
    super.key,
    required this.userName,
    required this.location,
    this.avatarUrl,
    required this.isUploadingImage,
    required this.onPickImage,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Avatar centered (no camera controls on profile screen)
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade200,
          child: (avatarUrl != null && avatarUrl!.isNotEmpty)
              ? ClipOval(
                  child: Image.network(
                    avatarUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                )
              : const Icon(Icons.person, size: 50, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        // User name
        Text(
          userName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        // Location with wilaya/baladiya
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: AppConstants.iconSmall,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: AppConstants.spacing4),
              Text(
                location,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
