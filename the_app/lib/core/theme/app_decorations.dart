import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized BoxDecoration definitions for consistent styling
///
/// Consolidates 179+ duplicate BoxDecoration instances across the app
///
/// Usage:
/// ```dart
/// Container(decoration: AppDecorations.card())
/// Container(decoration: AppDecorations.badge(color: Colors.red))
/// Container(decoration: AppDecorations.primaryGradient())
/// ```
class AppDecorations {
  AppDecorations._(); // Private constructor to prevent instantiation

  // ==================== CARDS ====================

  /// Standard card decoration with shadow
  ///
  /// Used for: Product cards, store cards, content containers
  static BoxDecoration card({
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      boxShadow: boxShadow ?? [cardShadow],
    );
  }

  /// Large card decoration with 20px border radius
  ///
  /// Used for: Featured items, prominent containers
  static BoxDecoration cardLarge({
    Color? color,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: boxShadow ?? [cardShadow],
    );
  }

  /// Small card decoration with 12px border radius
  ///
  /// Used for: Compact items, nested cards
  static BoxDecoration cardSmall({
    Color? color,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: boxShadow ?? [cardShadow],
    );
  }

  /// Card with no shadow (flat design)
  static BoxDecoration cardFlat({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
    );
  }

  // ==================== BADGES ====================

  /// Generic badge decoration
  ///
  /// Used for: Discount badges, status badges, count indicators
  static BoxDecoration badge({
    Color? color,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? Colors.red,
      borderRadius: BorderRadius.circular(borderRadius ?? 8),
    );
  }

  /// Discount badge (red background)
  static BoxDecoration discountBadge() {
    return BoxDecoration(
      color: AppColors.errorRed,
      borderRadius: BorderRadius.circular(8),
    );
  }

  /// Info badge (purple background)
  static BoxDecoration infoBadge() {
    return BoxDecoration(
      color: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(8),
    );
  }

  /// Success badge (green background)
  static BoxDecoration successBadge() {
    return BoxDecoration(
      color: AppColors.successGreen,
      borderRadius: BorderRadius.circular(8),
    );
  }

  /// Warning badge (orange/yellow background)
  static BoxDecoration warningBadge() {
    return BoxDecoration(
      color: AppColors.ratingYellow,
      borderRadius: BorderRadius.circular(8),
    );
  }

  // ==================== STATUS INDICATORS ====================

  /// Circular status indicator
  ///
  /// Used for: Online/offline status, availability indicators
  static BoxDecoration statusIndicator({
    required Color color,
    Color? borderColor,
    double? borderWidth,
  }) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: borderColor != null
          ? Border.all(color: borderColor, width: borderWidth ?? 2)
          : null,
    );
  }

  /// Online status indicator (green circle)
  static BoxDecoration onlineIndicator({Color borderColor = Colors.white}) {
    return statusIndicator(
      color: AppColors.successGreen,
      borderColor: borderColor,
      borderWidth: 2,
    );
  }

  /// Offline status indicator (gray circle)
  static BoxDecoration offlineIndicator({Color borderColor = Colors.white}) {
    return statusIndicator(
      color: AppColors.textHint,
      borderColor: borderColor,
      borderWidth: 2,
    );
  }

  // ==================== GRADIENTS ====================

  /// Generic gradient decoration
  static BoxDecoration gradient({
    required Gradient gradient,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      boxShadow: boxShadow,
    );
  }

  /// Primary gradient decoration (purple gradient)
  static BoxDecoration primaryGradient({
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      boxShadow: boxShadow ?? AppColors.primaryShadow,
    );
  }

  /// Deep gradient decoration (deep purple/blue gradient)
  static BoxDecoration deepGradient({
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: AppColors.deepGradient,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      boxShadow: boxShadow,
    );
  }

  /// Gold gradient decoration
  static BoxDecoration goldGradient({
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: AppColors.goldGradient,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      boxShadow: boxShadow,
    );
  }

  // ==================== OVERLAYS ====================

  /// Semi-transparent overlay
  ///
  /// Used for: Modal backgrounds, image overlays, disabled states
  static BoxDecoration overlay({
    Color? color,
    double? opacity,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.black).withValues(alpha: opacity ?? 0.5),
      borderRadius: borderRadius,
    );
  }

  /// Dark overlay for unavailable items
  static BoxDecoration unavailableOverlay({BorderRadius? borderRadius}) {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: borderRadius,
    );
  }

  /// Light overlay for subtle dimming
  static BoxDecoration lightOverlay({BorderRadius? borderRadius}) {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.2),
      borderRadius: borderRadius,
    );
  }

  // ==================== INPUT FIELDS ====================

  /// Input field decoration
  ///
  /// Used for: Text fields, search bars, form inputs
  static BoxDecoration inputField({
    Color? fillColor,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: fillColor ?? Colors.grey[100],
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: border,
    );
  }

  /// Input field with border
  static BoxDecoration inputFieldBordered({
    Color? fillColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: fillColor ?? Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: Border.all(
        color: borderColor ?? AppColors.borderLight,
        width: borderWidth ?? 1,
      ),
    );
  }

  /// Active/focused input field
  static BoxDecoration inputFieldActive({
    Color? fillColor,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: fillColor ?? Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.primary,
        width: 2,
      ),
    );
  }

  // ==================== BUTTONS ====================

  /// Rounded button decoration
  static BoxDecoration button({
    required Color color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: boxShadow,
    );
  }

  /// Outlined button decoration
  static BoxDecoration buttonOutlined({
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: Border.all(
        color: borderColor ?? AppColors.primary,
        width: borderWidth ?? 1.5,
      ),
    );
  }

  // ==================== SHADOWS ====================

  /// Standard card shadow
  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      );

  /// Soft shadow for subtle elevation
  static BoxShadow get softShadow => BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      );

  /// Strong shadow for prominent elements
  static BoxShadow get strongShadow => BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 16,
        offset: const Offset(0, 6),
      );

  /// Bottom shadow only
  static BoxShadow get bottomShadow => BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 4),
      );

  // ==================== PRODUCT-SPECIFIC ====================

  /// Product card decoration (from lib design system)
  static BoxDecoration productCard({
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.blackColor10,
        width: 1.5,
      ),
    );
  }

  /// Store card decoration
  static BoxDecoration storeCard({
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.borderPrimary,
        width: 1,
      ),
      boxShadow: [softShadow],
    );
  }

  // ==================== SEARCH & FILTERS ====================

  /// Search bar decoration (from lib design system)
  static BoxDecoration searchBar({
    Color? fillColor,
  }) {
    return BoxDecoration(
      color: fillColor ?? AppColors.lightGreyColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.transparent,
        width: 0,
      ),
    );
  }

  /// Filter chip decoration
  static BoxDecoration filterChip({
    required bool isActive,
  }) {
    return BoxDecoration(
      color: isActive ? AppColors.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isActive ? AppColors.primaryColor : AppColors.blackColor20,
        width: 1.5,
      ),
    );
  }

  // ==================== CIRCULAR ====================

  /// Circle decoration (for avatars, icons, etc.)
  static BoxDecoration circle({
    Color? color,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      shape: BoxShape.circle,
      border: border,
    );
  }

  /// Circle with border
  static BoxDecoration circleBordered({
    Color? color,
    Color? borderColor,
    double? borderWidth,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      shape: BoxShape.circle,
      border: Border.all(
        color: borderColor ?? AppColors.borderPrimary,
        width: borderWidth ?? 2,
      ),
    );
  }

  // ==================== BOTTOM SHEETS & MODALS ====================

  /// Bottom sheet decoration (from lib design system)
  static BoxDecoration bottomSheet({
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    );
  }

  /// Modal decoration
  static BoxDecoration modal({
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [strongShadow],
    );
  }
}
