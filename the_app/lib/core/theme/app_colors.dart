import 'package:flutter/material.dart';

/// Modern Blue Color Palette - Clean Shopping Experience
class AppColors {
  // ===== PRIMARY COLORS =====
  /// Modern blue tones for the app
  static const Color primaryBlue = Color(0xFF3B82F6);           // Main blue for buttons
  static const Color primaryDeep = Color(0xFF1E3A5F);           // Deep navy for headers
  static const Color primaryLight = Color(0xFFF8FAFC);          // Light background
  static const Color primaryBlueDark = Color(0xFF2563EB);       // Darker blue for pressed states
  static const Color primaryBlueLight = Color(0xFFDBEAFE);      // Light blue for backgrounds

  // Legacy alias
  static const Color primaryGold = primaryBlue;
  static const Color primaryOrange = primaryBlue;
  static const Color primaryPurple = primaryDeep;

  // ===== ACCENT COLORS =====
  static const Color accentRose = Color(0xFFFDA4AF);            // Soft rose
  static const Color accentTeal = Color(0xFF14B8A6);            // Teal
  static const Color accentPurple = Color(0xFF8B5CF6);          // Purple

  // ===== STATUS & SEMANTIC COLORS =====
  static const Color successGreen = Color(0xFF10B981);          // Success green
  static const Color warningAmber = Color(0xFFF59E0B);          // Warning amber
  static const Color errorRed = Color(0xFFEF4444);              // Error red
  static const Color infoBlue = Color(0xFF3B82F6);              // Info blue

  // ===== NEUTRAL PALETTE =====
  static const Color neutralDarkest = Color(0xFF1F2937);        // Near black
  static const Color neutralDark = Color(0xFF374151);           // Dark gray
  static const Color neutralMedium = Color(0xFF6B7280);         // Medium gray
  static const Color neutralLight = Color(0xFFF3F4F6);          // Light gray
  static const Color neutralLightest = Color(0xFFFFFFFF);       // Pure white

  // ===== SURFACE COLORS =====
  static const Color surfacePrimary = Color(0xFFFFFFFF);        // White
  static const Color surfaceSecondary = Color(0xFFF9FAFB);      // Very light gray
  static const Color surfaceTertiary = Color(0xFFF3F4F6);       // Light gray
  static const Color surfaceOverlay = Color(0x40000000);        // 25% black overlay

  // ===== GRADIENTS =====
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6),  // Primary blue
      Color(0xFF2563EB),  // Darker blue
    ],
  );

  static const LinearGradient deepGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E3A5F),  // Deep navy
      Color(0xFF2D4A6F),  // Lighter navy
    ],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF1D4ED8),
    ],
  );

  static const LinearGradient roseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFEE2E2),
      Color(0xFFFDA4AF),
    ],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF5EEAD4),
      Color(0xFF14B8A6),
    ],
  );

  static const LinearGradient featuredGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDBEAFE),
      Color(0xFF3B82F6),
    ],
  );

  // ===== GLASS MORPHISM EFFECTS =====
  static const Color glassPrimary = Color(0x15FFFFFF);
  static const Color glassSecondary = Color(0x20FFFFFF);
  static const Color glassTertiary = Color(0x30FFFFFF);
  static const Color glassBlur = Color(0x40000000);

  // ===== SHADOWS =====
  static const List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> goldShadow = [
    BoxShadow(
      color: Color(0x1A3B82F6),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> innerShadow = [
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  // ===== INTERACTIVE STATES =====
  static const Color hoverOverlay = Color(0x08000000);
  static const Color pressedOverlay = Color(0x12000000);
  static const Color focusedOverlay = Color(0x153B82F6);
  static const Color disabledOverlay = Color(0x40FFFFFF);

  // ===== BORDER COLORS =====
  static const Color borderPrimary = Color(0xFFE5E7EB);         // Light gray border
  static const Color borderSecondary = Color(0xFFF3F4F6);       // Very light border
  static const Color borderGold = Color(0x603B82F6);            // Blue border
  static const Color borderTeal = Color(0x6014B8A6);            // Teal border

  // ===== PRODUCT CARD COLORS =====
  static const Color productCardBg = Color(0xFFFFFFFF);
  static const Color productCardBorder = Color(0xFFE5E7EB);
  static const Color priceColor = Color(0xFF1E3A5F);            // Navy for price
  static const Color originalPriceColor = Color(0xFF9CA3AF);    // Gray for old price
  static const Color discountBadge = Color(0xFFEF4444);         // Red for discount
  static const Color favoriteIcon = Color(0xFFEF4444);          // Red for favorite

  // ===== STORE BRANDING COLORS =====
  static const Color storeBadgeGold = Color(0xFFF59E0B);        // Gold/amber
  static const Color storeBadgeSilver = Color(0xFF9CA3AF);      // Silver
  static const Color storeBadgeBronze = Color(0xFFD97706);      // Bronze
  static const Color storeVerifiedBadge = Color(0xFF3B82F6);    // Blue verified

  // ===== BACKWARD COMPATIBILITY =====
  static const Color backgroundLight = surfacePrimary;
  static const Color textPrimary = neutralDarkest;
  static const Color textSecondary = neutralMedium;
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color cardBackground = productCardBg;
  static const Color cardWhite = surfacePrimary;
  static const Color scaffoldBackground = Color(0xFFFAFAFA);
  static const Color searchBarBackground = surfaceSecondary;
  static const Color ratingYellow = Color(0xFFF59E0B);
  static const Color borderLight = borderPrimary;

  // Legacy shadow mappings
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x10000000),
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );

  // Legacy gradient mappings
  static const LinearGradient primaryGradient = blueGradient;
  static const LinearGradient purpleGradient = deepGradient;

  // Backward-compatible aliases
  static const Color primary = primaryBlue;
  static const Color merchantStart = Color(0xFF3B82F6);
  static const Color merchantEnd = Color(0xFF1D4ED8);
  static const Color userStart = Color(0xFFDBEAFE);
  static const Color userEnd = Color(0xFF3B82F6);

  // Category colors
  static const Color categoryElectronics = Color(0xFF3B82F6);
  static const Color categoryFashion = Color(0xFFEC4899);
  static const Color categoryHome = Color(0xFF10B981);
  static const Color categorySports = Color(0xFFF59E0B);

  // Deal colors
  static const Color hotDealRed = Color(0xFFEF4444);

  // Shadow colors
  static const Color shadowColor = Color(0x15000000);

  // Notification colors
  static const Color notificationBlue = Color(0xFFDBEAFE);
  static const Color notificationGreen = Color(0xFFD1FAE5);
  static const Color notificationYellow = Color(0xFFFEF3C7);

  // ===== UTILITY METHODS =====
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
