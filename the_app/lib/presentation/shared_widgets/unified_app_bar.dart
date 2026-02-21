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

  void _showRadiusPicker(BuildContext context) {
    final options = [5.0, 10.0, 25.0, 50.0, 100.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Search Radius',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...options.map((km) => ListTile(
                leading: Icon(
                  radiusKm == km ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: AppColors.primaryColor,
                ),
                title: Text('${km.toInt()} km'),
                onTap: () {
                  Navigator.pop(ctx);
                  onRadiusChanged?.call(km);
                },
              )),
            ],
          ),
        ),
      ),
    );
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
                  if (showLocation) ...[
                    Expanded(
                      child: GestureDetector(
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
                            Flexible(
                              child: Column(
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
                                      Flexible(
                                        child: Text(
                                          location ?? 'Select location',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Radius chip — always visible; shows "/" when address mode is active
                    if (onRadiusChanged != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showRadiusPicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: radiusKm != null
                                ? AppColors.primaryColor.withOpacity(0.10)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: radiusKm != null
                                  ? AppColors.primaryColor.withOpacity(0.25)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.radar,
                                size: 14,
                                color: radiusKm != null
                                    ? AppColors.primaryColor
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                radiusKm != null ? '${radiusKm!.toInt()} km' : '/',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: radiusKm != null
                                      ? AppColors.primaryColor
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (!showLocation) const Spacer(),

                  const SizedBox(width: 8),

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
