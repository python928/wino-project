import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Travo-style card styling — white, 16px corners, soft shadow, no border
class CardStyles {
  CardStyles._();

  /// Standard border radius for cards
  static const double radius = 16.0;

  /// Standard shadow opacity
  static const double shadowOpacity = 0.07;

  /// Standard shadow blur
  static const double shadowBlur = 16.0;

  /// Standard shadow offset
  static const Offset shadowOffset = Offset(0, 4);

  static BorderRadius get standardRadius => BorderRadius.circular(radius);

  static List<BoxShadow> get standardShadow => [
        BoxShadow(
          color: const Color(0xFF7B61FF).withOpacity(0.08),
          blurRadius: shadowBlur,
          offset: shadowOffset,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(shadowOpacity),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Standard card — white, rounded, shadow, NO border
  static BoxDecoration standard({
    Color? color,
    List<BoxShadow>? boxShadow,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: standardRadius,
      boxShadow: boxShadow ?? standardShadow,
    );
  }

  /// No-border variant (same as standard now)
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

  /// No-shadow variant (for nested cards)
  static BoxDecoration noShadow({
    Color? color,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: standardRadius,
      border: border,
    );
  }
}
