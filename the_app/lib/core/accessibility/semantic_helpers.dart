import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility helpers for screen readers and assistive technologies
/// Following WCAG 2.1 AA standards

class SemanticHelpers {
  /// Minimum touch target size (48x48dp per Material Design guidelines)
  static const double minTouchTargetSize = 48.0;

  /// Wrap a widget with semantic labels for better accessibility
  static Widget withLabel({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool excludeSemantics = false,
    bool isButton = false,
    bool isLink = false,
    bool isHeader = false,
    bool isImage = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: isButton,
      link: isLink,
      header: isHeader,
      image: isImage,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      child: child,
    );
  }

  /// Create a semantic button with proper touch targets
  static Widget button({
    required Widget child,
    required String label,
    required VoidCallback onPressed,
    String? hint,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      onTap: enabled ? onPressed : null,
      child: child,
    );
  }

  /// Create a semantic link
  static Widget link({
    required Widget child,
    required String label,
    required VoidCallback onTap,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      link: true,
      onTap: onTap,
      child: child,
    );
  }

  /// Create a semantic header
  static Widget header({
    required Widget child,
    required String label,
    int level = 1,
  }) {
    return Semantics(
      label: label,
      header: true,
      sortKey: OrdinalSortKey(level.toDouble()),
      child: child,
    );
  }

  /// Create a semantic image with description
  static Widget image({
    required Widget child,
    required String description,
  }) {
    return Semantics(
      label: description,
      image: true,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Create a live region for dynamic content
  static Widget liveRegion({
    required Widget child,
    required String label,
    bool liveRegion = true,
  }) {
    return Semantics(
      label: label,
      liveRegion: liveRegion,
      child: child,
    );
  }

  /// Announce a message to screen readers
  static void announce(
    BuildContext context,
    String message, {
    Assertiveness assertiveness = Assertiveness.polite,
  }) {
    SemanticsService.announce(
      message,
      assertiveness == Assertiveness.polite
          ? TextDirection.ltr
          : TextDirection.rtl,
    );
  }

  /// Check if screen reader is enabled
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// Get recommended font scale
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.textScaleFactorOf(context);
  }

  /// Check if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Check if bold text is enabled
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.boldTextOf(context);
  }

  /// Ensure minimum touch target size
  static Widget ensureTouchTarget({
    required Widget child,
    double minSize = minTouchTargetSize,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: child,
    );
  }

  /// Create an accessible card
  static Widget accessibleCard({
    required Widget child,
    required String label,
    VoidCallback? onTap,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      onTap: onTap,
      container: true,
      child: child,
    );
  }

  /// Format price for screen readers
  static String formatPriceForScreenReader(double price, String currency) {
    return '$price $currency';
  }

  /// Format rating for screen readers
  static String formatRatingForScreenReader(double rating, int maxRating) {
    return '$rating out of $maxRating stars';
  }

  /// Format distance for screen readers
  static String formatDistanceForScreenReader(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()} meters away';
    }
    return '${distance.toStringAsFixed(1)} kilometers away';
  }

  /// Create semantic list
  static Widget list({
    required Widget child,
    required int itemCount,
    String? label,
  }) {
    return Semantics(
      label: label ?? 'List with $itemCount items',
      container: true,
      child: child,
    );
  }

  /// Create semantic slider
  static Widget slider({
    required Widget child,
    required String label,
    required double value,
    required double min,
    required double max,
    ValueChanged<double>? onChanged,
  }) {
    return Semantics(
      label: label,
      value: value.toStringAsFixed(1),
      slider: true,
      onIncrease: onChanged != null
          ? () {
              final newValue = (value + (max - min) * 0.1).clamp(min, max);
              onChanged(newValue);
            }
          : null,
      onDecrease: onChanged != null
          ? () {
              final newValue = (value - (max - min) * 0.1).clamp(min, max);
              onChanged(newValue);
            }
          : null,
      child: child,
    );
  }

  /// Create semantic checkbox
  static Widget checkbox({
    required Widget child,
    required String label,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return Semantics(
      label: label,
      checked: value,
      enabled: onChanged != null,
      onTap: onChanged != null ? () => onChanged(!value) : null,
      child: child,
    );
  }

  /// Create semantic switch
  static Widget switchWidget({
    required Widget child,
    required String label,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return Semantics(
      label: label,
      toggled: value,
      enabled: onChanged != null,
      onTap: onChanged != null ? () => onChanged(!value) : null,
      child: child,
    );
  }

  /// Create semantic text field
  static Widget textField({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool obscureText = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      textField: true,
      obscured: obscureText,
      child: child,
    );
  }

  /// Create focus traversal order
  static FocusTraversalOrder orderedFocus({
    required Widget child,
    required double order,
  }) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: child,
    );
  }
}

enum Assertiveness {
  polite,
  assertive,
}

/// Semantic wrapper widget for common use cases
class SemanticWrapper extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final String? value;
  final bool isButton;
  final bool isLink;
  final bool isHeader;
  final bool isImage;
  final VoidCallback? onTap;

  const SemanticWrapper({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.value,
    this.isButton = false,
    this.isLink = false,
    this.isHeader = false,
    this.isImage = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelpers.withLabel(
      child: child,
      label: label,
      hint: hint,
      value: value,
      isButton: isButton,
      isLink: isLink,
      isHeader: isHeader,
      isImage: isImage,
      onTap: onTap,
    );
  }
}
