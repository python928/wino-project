import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_constants.dart';

/// Blur container with glass morphism effect
/// From lib design system
class BlurContainer extends StatelessWidget {
  final String text;
  final double height;
  final double width;
  final double fontSize;

  const BlurContainer({
    super.key,
    required this.text,
    this.height = 40,
    this.width = 40,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(
        Radius.circular(AppConstants.radiusSmall / 2),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          height: height,
          width: width,
          color: Colors.white12,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
