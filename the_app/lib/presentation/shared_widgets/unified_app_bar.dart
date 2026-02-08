import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/routes.dart';
import '../search/search_tab_screen.dart';
import '../notifications/notifications_screen.dart';

/// Unified app bar that appears across all main screens
/// Shows search and notification icons conditionally, with optional location display
class UnifiedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showLocation;
  final bool showNotificationIcon;
  final String? location;
  final VoidCallback? onLocationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final Color? backgroundColor;

  const UnifiedAppBar({
    super.key,
    this.showLocation = false,
    this.showNotificationIcon = true,
    this.location,
    this.onLocationTap,
    this.onSearchTap,
    this.onNotificationTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Location section (only on Home screen)
            if (showLocation) ...[
              GestureDetector(
                onTap: onLocationTap,
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.greyColor,
                          ),
                        ),
                        Text(
                          location ?? 'Select location',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blackColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Search Icon Button (always visible)
            IconButton(
              onPressed: onSearchTap ?? () {
                // Navigate to search screen as full page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchTabScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.search,
                color: AppColors.blackColor,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            const SizedBox(width: 16),

            // Notification Icon Button (hidden on notifications screen)
            if (showNotificationIcon)
              IconButton(
                onPressed: onNotificationTap ?? () {
                  // Navigate to notifications screen as full page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.notifications_outlined,
                  color: AppColors.blackColor,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
