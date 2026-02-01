import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Centralized InputDecoration definitions for consistent TextField styling.
///
/// Refactored to use a builder pattern for cleaner, more maintainable code.
class AppInputDecorations {
  AppInputDecorations._();

  // ==================== CONSTANTS ====================
  
  /// Border radius for all input fields
  static const double _radius = 12;

  /// Icon size for form fields (larger, prominent)
  static const double _iconSize = 28;

  /// Icon opacity for subtle appearance
  static const double _iconOpacity = 0.3;

  /// Border opacity for subtle appearance
  static const double _borderOpacity = 0.3;

  // ==================== BORDERS ====================

  /// Borderless outline (preserves rounded fill shape)
  static final InputBorder _borderlessOutline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_radius),
    borderSide: BorderSide.none,
  );

  /// Outline with subtle border (0.3 opacity)
  static final InputBorder _subtleBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_radius),
    borderSide: BorderSide(
      color: AppColors.textPrimary.withOpacity(_borderOpacity),
      width: 1,
    ),
  );

  // ==================== BASE BUILDER ====================

  /// Base InputDecoration builder with common properties
  static InputDecoration _base({
    required String hintText,
    TextStyle? hintStyle,
    String? labelText,
    String? errorText,
    String? suffixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: hintStyle ?? AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
      labelText: labelText,
      errorText: errorText,
      suffixText: suffixText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor ?? AppColors.neutral50,
      border: _subtleBorder,
      enabledBorder: _subtleBorder,
      focusedBorder: _subtleBorder,
      errorBorder: _subtleBorder,
      focusedErrorBorder: _subtleBorder,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }

  /// Helper to create icon with opacity
  static Widget _icon(IconData icon, {double? size, Color? color}) {
    return Icon(
      icon,
      color: (color ?? AppColors.textPrimary).withOpacity(_iconOpacity),
      size: size ?? _iconSize,
    );
  }

  // ==================== PUBLIC DECORATIONS ====================

  /// Standard form field decoration (filled, with subtle border and icon)
  ///
  /// Used for: Login, Register, Profile forms, Add/Edit screens
  static InputDecoration form({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? labelText,
    String? errorText,
    String? suffixText,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return _base(
      hintText: hintText,
      labelText: labelText,
      errorText: errorText,
      suffixText: suffixText,
      prefixIcon: prefixIcon != null ? _icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding,
    );
  }

  /// Profile form style (same as form, for consistency)
  ///
  /// Used by: Edit screens, profile forms
  static InputDecoration profileForm({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return form(
      hintText: hintText,
      prefixIcon: prefixIcon,
    );
  }

  /// Search field decoration (with subtle border and icon opacity)
  ///
  /// Used for: Search bars, filter pickers, category search
  static InputDecoration search({
    required String hintText,
    Widget? suffixIcon,
    bool showBorder = false,
    Color? fillColor,
  }) {
    return _base(
      hintText: hintText,
      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
      prefixIcon: _icon(Icons.search_rounded, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      fillColor: fillColor ?? const Color(0xFFF5F6F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  /// Compact search (for modals)
  static InputDecoration searchCompact({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return _base(
      hintText: hintText,
      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
      prefixIcon: _icon(Icons.search, size: 22, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      fillColor: const Color(0xFFF5F6F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  /// Multiline / comment field (for reviews, descriptions)
  static InputDecoration multiline({
    required String hintText,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return _base(
      hintText: hintText,
      contentPadding: contentPadding,
    );
  }

  /// Simple outlined (for add_pack, add_promotion style)
  static InputDecoration outlined({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return _base(
      hintText: hintText ?? '',
      labelText: labelText,
      suffixText: suffixText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  /// App bar search
  static InputDecoration appBarSearch({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return _base(
      hintText: hintText,
      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: _iconSize),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }
}
