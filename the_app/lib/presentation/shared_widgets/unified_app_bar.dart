import 'package:flutter/material.dart';
import '../../core/services/notification_badge_service.dart';
import '../../core/theme/app_colors.dart';
import '../search/search_tab_screen.dart';
import '../notifications/notifications_screen.dart';
import '../common/radius_picker_sheet.dart';
import 'location_mode_switcher.dart';

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
  final double? radiusKm;
  final ValueChanged<double>? onRadiusChanged;

  const UnifiedAppBar({
    super.key,
    this.showLocation = false,
    this.showNotificationIcon = true,
    this.location,
    this.onLocationTap,
    this.onSearchTap,
    this.onNotificationTap,
    this.backgroundColor,
    this.radiusKm,
    this.onRadiusChanged,
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
                  if (Navigator.canPop(context)) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (showLocation) ...[
                    Expanded(
                      child: LocationModeSwitcher(
                        distanceActive: radiusKm != null,
                        cityLabel: (location != null &&
                                location!.isNotEmpty &&
                                location != '/')
                            ? location!
                            : 'City',
                        nearbyLabel: radiusKm != null
                            ? '${radiusKm!.toInt()} km'
                            : 'Nearby',
                        onCityTap: onLocationTap ?? () {},
                        onNearbyTap: () {
                          if (onRadiusChanged == null) return;
                          showRadiusPickerSheet(
                            context,
                            initialRadius: radiusKm ?? 20.0,
                            onRadiusChanged: onRadiusChanged!,
                          );
                        },
                        showNearby: onRadiusChanged != null,
                      ),
                    ),
                  ],
                  if (!showLocation) const Spacer(),

                  const SizedBox(width: 8),

                  // Search icon button
                  _IconBtn(
                    icon: Icons.search_rounded,
                    onTap: onSearchTap ??
                        () {
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
                    ValueListenableBuilder<int>(
                      valueListenable:
                          NotificationBadgeService.instance.unreadCount,
                      builder: (context, unread, _) => _IconBtn(
                        icon: Icons.notifications_outlined,
                        badgeCount: unread > 0 ? unread : null,
                        onTap: onNotificationTap ??
                            () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotificationsScreen(),
                                ),
                              );
                              NotificationBadgeService.instance.refresh();
                            },
                      ),
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
  final int? badgeCount;
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.badgeCount,
  });

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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.primaryColor, size: 20),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    badgeCount! > 99 ? '99+' : badgeCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
