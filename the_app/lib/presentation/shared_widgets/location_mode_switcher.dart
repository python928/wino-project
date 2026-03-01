import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LocationModeSwitcher extends StatelessWidget {
  final bool distanceActive;
  final String cityLabel;
  final String nearbyLabel;
  final VoidCallback onCityTap;
  final VoidCallback onNearbyTap;
  final double height;
  final bool showNearby;

  const LocationModeSwitcher({
    super.key,
    required this.distanceActive,
    required this.cityLabel,
    required this.nearbyLabel,
    required this.onCityTap,
    required this.onNearbyTap,
    this.height = 44,
    this.showNearby = true,
  });

  @override
  Widget build(BuildContext context) {
    final citySelected = !distanceActive;
    final align = citySelected ? Alignment.centerLeft : Alignment.centerRight;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: const Color(0xFFDDE5FF)),
      ),
      child: Stack(
        children: [
          if (showNearby)
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              alignment: align,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E5BFF), Color(0xFF4A7DFF)],
                    ),
                    borderRadius: BorderRadius.circular((height - 6) / 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E5BFF), Color(0xFF4A7DFF)],
                ),
                borderRadius: BorderRadius.circular((height - 6) / 2),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  selected: citySelected || !showNearby,
                  icon: Icons.location_on_outlined,
                  label: cityLabel,
                  onTap: onCityTap,
                ),
              ),
              if (showNearby)
                Expanded(
                  child: _ModeButton(
                    selected: !citySelected,
                    icon: Icons.radar,
                    label: nearbyLabel,
                    onTap: onNearbyTap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
