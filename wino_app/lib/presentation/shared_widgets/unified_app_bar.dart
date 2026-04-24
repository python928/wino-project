import 'package:wino/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

import '../../core/services/notification_badge_service.dart';
import '../common/location_permission_helper.dart';
import '../common/radius_picker_sheet.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_tab_screen.dart';
import 'app_icon_action_button.dart';
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
  final bool isNearbyLoading;

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
    this.isNearbyLoading = false,
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
                    AppBackActionButton(
                      onTap: () => Navigator.pop(context),
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
                            ? _localizedLocation(context, location!)
                            : context.tr('City'),
                        nearbyLabel: radiusKm != null
                            ? '${radiusKm!.toInt()} ${context.tr('km')}'
                            : context.tr('Nearby'),
                        onCityTap: onLocationTap ?? () {},
                        onNearbyTap: () async {
                          if (onRadiusChanged == null) return;
                          final shouldContinue = await LocationPermissionHelper
                              .ensureEducationShown(
                            context,
                            flow: LocationEducationFlow.nearbySearch,
                          );
                          if (!shouldContinue || !context.mounted) return;
                          showRadiusPickerSheet(
                            context,
                            initialRadius: radiusKm ?? 20.0,
                            onRadiusChanged: onRadiusChanged!,
                          );
                        },
                        showNearby: onRadiusChanged != null,
                        isLoadingNearby: isNearbyLoading,
                      ),
                    ),
                  ],
                  if (!showLocation) const Spacer(),

                  const SizedBox(width: 8),

                  // Search icon button
                  AppIconActionButton(
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
                      builder: (context, unread, _) => AppIconActionButton(
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
