import 'package:flutter/material.dart';
import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import '../../core/theme/app_colors.dart';

class LocationModeSwitcher extends StatelessWidget {
  final bool distanceActive;
  final String cityLabel;
  final String nearbyLabel;
  final VoidCallback onCityTap;
  final VoidCallback onNearbyTap;
  final double height;
  final bool showNearby;
  final bool isLoadingNearby;
  final String loadingNearbyLabel;

  const LocationModeSwitcher({
    super.key,
    required this.distanceActive,
    required this.cityLabel,
    required this.nearbyLabel,
    required this.onCityTap,
    required this.onNearbyTap,
    this.height = 44,
    this.showNearby = true,
    this.isLoadingNearby = false,
    this.loadingNearbyLabel = 'Locating...',
  });

  @override
  Widget build(BuildContext context) {
    final citySelected = !distanceActive;
    final align = citySelected
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd;
    final effectiveLoadingNearbyLabel = context.tr(loadingNearbyLabel);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.blackColor5,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: const Color(0xFFE6E6E6)),
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
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular((height - 6) / 2),
                  ),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
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
                  onTap: isLoadingNearby ? () {} : onCityTap,
                ),
              ),
              if (showNearby)
                Expanded(
                  child: _ModeButton(
                    selected: !citySelected,
                    icon: isLoadingNearby ? null : Icons.radar,
                    label: isLoadingNearby
                        ? effectiveLoadingNearbyLabel
                        : nearbyLabel,
                    onTap: isLoadingNearby ? () {} : onNearbyTap,
                    loading: isLoadingNearby,
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
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const _ModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            if (loading || icon != null) const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
