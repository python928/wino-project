import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Standardized button styles for the entire app
/// Ensures consistency across all buttons
class ButtonStyles {
  // Standard dimensions
  static const double height = 56.0;
  static const double borderRadius = 16.0;
  static const double fontSize = 16.0;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  /// Primary button - Purple filled
  static ButtonStyle primary({
    Color? backgroundColor,
    Color? foregroundColor,
    double? height,
    double? borderRadius,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      minimumSize: Size(double.infinity, height ?? ButtonStyles.height),
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? ButtonStyles.borderRadius),
      ),
      elevation: 0,
      textStyle: const TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Secondary button - Outlined with purple border
  static ButtonStyle secondary({
    Color? borderColor,
    Color? foregroundColor,
    double? height,
    double? borderRadius,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor ?? AppColors.primaryColor,
      minimumSize: Size(double.infinity, height ?? ButtonStyles.height),
      padding: padding,
      side: BorderSide(
        color: borderColor ?? AppColors.primaryColor,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? ButtonStyles.borderRadius),
      ),
      textStyle: const TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Text button - No background
  static ButtonStyle text({
    Color? foregroundColor,
    double? height,
  }) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor ?? AppColors.primaryColor,
      minimumSize: Size(0, height ?? 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Small primary button - Compact version
  static ButtonStyle primarySmall({
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Small secondary button - Compact outlined version
  static ButtonStyle secondarySmall({
    Color? borderColor,
    Color? foregroundColor,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor ?? AppColors.primaryColor,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      side: BorderSide(
        color: borderColor ?? AppColors.primaryColor,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Danger button - Red for destructive actions
  static ButtonStyle danger({
    double? height,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      minimumSize: Size(double.infinity, height ?? ButtonStyles.height),
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
      textStyle: const TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
