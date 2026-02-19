import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../search/search_tab_screen.dart';
import '../notifications/notifications_screen.dart';

/// Unified app bar — Travo style
/// White background, location row, pill search hint, notification bell
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
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: location + icons
              Row(
                children: [
                  if (showLocation) ...[
                    GestureDetector(
                      onTap: onLocationTap,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    location ?? 'Select location',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),

                  // Search icon button
                  _IconBtn(
                    icon: Icons.search_rounded,
                    onTap: onSearchTap ?? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchTabScreen(),
                        ),
                      );
                    },
                  ),

                  if (showNotificationIcon) ...[
                    const SizedBox(width: 8),
                    _IconBtn(
                      icon: Icons.notifications_outlined,
                      onTap: onNotificationTap ?? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(68);
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryColor, size: 20),
      ),
    );
  }
}
