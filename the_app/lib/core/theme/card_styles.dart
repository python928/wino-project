import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Standardized card styling for consistent UI across the app
class CardStyles {
  CardStyles._();

  /// Standard border radius for all cards
  static const double radius = 12.0;

  /// Standard border width
  static const double borderWidth = 1.0;

  /// Standard border opacity
  static const double borderOpacity = 0.3;

  /// Standard shadow opacity
  static const double shadowOpacity = 0.06;

  /// Standard shadow blur radius
  static const double shadowBlur = 8.0;

  /// Standard shadow offset
  static const Offset shadowOffset = Offset(0, 2);

  /// Standard border radius
  static BorderRadius get standardRadius => BorderRadius.circular(radius);

  /// Standard box shadow
  static List<BoxShadow> get standardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(shadowOpacity),
          blurRadius: shadowBlur,
          offset: shadowOffset,
        ),
      ];

  /// Standard border
  static Border get standardBorder => Border.all(
        color: AppColors.textPrimary.withOpacity(borderOpacity),
        width: borderWidth,
      );

  /// Standard card decoration
  static BoxDecoration standard({
    Color? color,
    List<BoxShadow>? boxShadow,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: standardRadius,
      border: border ?? standardBorder,
      boxShadow: boxShadow ?? standardShadow,
    );
  }

  /// Card decoration without border
  static BoxDecoration noBorder({
    Color? color,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: standardRadius,
      boxShadow: boxShadow ?? standardShadow,
    );
  }

  /// Card decoration without shadow
  static BoxDecoration noShadow({
    Color? color,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: standardRadius,
      border: border ?? standardBorder,
    );
  }
}
