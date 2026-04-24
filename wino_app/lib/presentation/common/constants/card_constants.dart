import 'package:flutter/material.dart';

/// Common constants for all item cards (Products, Promotions, Packs)
/// Ensures consistent UI/UX across the application
class CardConstants {
  // Card Layout
  static const double borderRadius = 16.0;
  static const double shadowBlurRadius = 12.0;
  static const double shadowOpacity = 0.08;
  static const Offset shadowOffset = Offset(0, 4);
  static const double imageAspectRatio = 1.0;

  // Padding & Spacing
  static const EdgeInsets contentPadding = EdgeInsets.all(10);
  static const double gridHorizontalPadding = 16.0;
  static const double gridVerticalPadding = 12.0;
  static const double gridCrossAxisSpacing = 14.0;
  static const double gridMainAxisSpacing = 14.0;
  // Smaller value => taller tiles (width/height)
  static const double gridChildAspectRatio = 0.62;

  // Typography
  static const double titleFontSize = 13.0;
  static const double priceFontSize = 14.0;
  static const double oldPriceFontSize = 11.0;
  static const double ratingFontSize = 11.0;
  static const double badgeFontSize = 11.0;
  static const double additionalInfoFontSize = 11.0;
  static const double titleLineHeight = 1.2;

  // Icon Sizes
  static const double editIconSize = 16.0;
  static const double ratingStarSize = 12.0;
  static const double badgeIconPadding = 8.0;
  static const double editButtonPadding = 6.0;

  // Badge
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );
  static const double badgeBorderRadius = 8.0;
  static const Offset badgePosition = Offset(8, 8);

  // Edit Button
  static const double editButtonBlurRadius = 6.0;
  static const double editButtonShadowOpacity = 0.15;

  // Spacing between elements
  static const double titleBottomSpacing = 4.0;
  static const double priceSpacing = 6.0;
  static const double ratingSpacing = 3.0;
  static const double betweenSections = 4.0;

  // Grid Configuration
  static const int gridCrossAxisCount = 2;

  // Shadow
  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(shadowOpacity),
        blurRadius: shadowBlurRadius,
        offset: shadowOffset,
      );

  static BoxShadow get editButtonShadow => BoxShadow(
        color: Colors.black.withOpacity(editButtonShadowOpacity),
        blurRadius: editButtonBlurRadius,
      );
}
