import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// Animated dot indicator for carousels and image galleries
/// From lib design system
class DotIndicator extends StatelessWidget {
  final bool isActive;
  final Color? inActiveColor;
  final Color activeColor;

  const DotIndicator({
    super.key,
    this.isActive = false,
    this.inActiveColor,
    this.activeColor = AppColors.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.defaultDuration,
      height: isActive ? 12 : 4,
      width: 4,
      decoration: BoxDecoration(
        color: isActive
            ? activeColor
            : inActiveColor ?? AppColors.primaryLightShade,
        borderRadius: BorderRadius.all(
          Radius.circular(AppConstants.defaultBorderRadius),
        ),
      ),
    );
  }
}
