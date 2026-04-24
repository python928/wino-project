import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular checkmark indicator
/// From lib design system (adapted to use Material Icons instead of SVG)
class CheckMark extends StatelessWidget {
  final Color activeColor;
  final double size;

  const CheckMark({
    super.key,
    this.activeColor = AppColors.successGreen,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: activeColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}
