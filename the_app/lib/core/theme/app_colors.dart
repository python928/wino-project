import 'package:flutter/material.dart';

/// Modern Purple Color Palette - Professional Shopping Experience
class AppColors {
  // ===== PRIMARY COLORS =====
  /// Modern purple primary color (migrated from lib design system)
  static const Color primaryColor = Color(0xFF7B61FF);          // Main purple for buttons and accents
  static const Color primaryDeep = Color(0xFF1E3A5F);           // Deep navy for headers
  static const Color primaryLight = Color(0xFFF8FAFC);          // Light background

  // Purple variations
  static const Color primaryDark = Color(0xFF6C56DD);           // Darker purple for pressed states
  static const Color primaryLightShade = Color(0xFFEFECFF);     // Light purple for backgrounds

  // Backward compatibility - map old blue to new purple
  @Deprecated('Use primaryColor instead')
  static const Color primaryBlue = primaryColor;
  @Deprecated('Use primaryColor instead')
  static const Color primaryBlueDark = primaryDark;
  @Deprecated('Use primaryLightShade instead')
  static const Color primaryBlueLight = primaryLightShade;

  // Legacy aliases
  static const Color primaryGold = primaryColor;
  static const Color primaryOrange = primaryColor;
  static const Color primaryPurple = primaryDeep;

  // ===== ACCENT COLORS =====
  static const Color accentRose = Color(0xFFFDA4AF);            // Soft rose
  static const Color accentTeal = Color(0xFF14B8A6);            // Teal
  static const Color accentPurple = Color(0xFF8B5CF6);          // Purple

  // ===== STATUS & SEMANTIC COLORS =====
  /// Status colors matching lib design system
  static const Color successGreen = Color(0xFF2ED573);          // Success green
  static const Color warningAmber = Color(0xFFFFBE21);          // Warning amber
  static const Color errorRed = Color(0xFFEA5B5B);              // Error red
  static const Color infoBlue = Color(0xFF7B61FF);              // Info purple

  // ===== BLACK & WHITE OPACITY SCALES (from lib design system) =====
  /// Black color with opacity variations
  static const Color blackColor = Color(0xFF16161E);            // Base black
  static const Color blackColor80 = Color(0xFF45454B);          // 80% opacity
  static const Color blackColor60 = Color(0xFF737378);          // 60% opacity
  static const Color blackColor40 = Color(0xFFA2A2A5);          // 40% opacity
  static const Color blackColor20 = Color(0xFFD0D0D2);          // 20% opacity
  static const Color blackColor10 = Color(0xFFE8E8E9);          // 10% opacity
  static const Color blackColor5 = Color(0xFFF3F3F4);           // 5% opacity

  /// White color with opacity variations
  static const Color whiteColor = Colors.white;                 // Base white
  static const Color whiteColor80 = Color(0xFFCCCCCC);          // 80% opacity
  static const Color whiteColor60 = Color(0xFF999999);          // 60% opacity
  static const Color whiteColor40 = Color(0xFF666666);          // 40% opacity
  static const Color whiteColor20 = Color(0xFF333333);          // 20% opacity
  static const Color whiteColor10 = Color(0xFF191919);          // 10% opacity
  static const Color whiteColor5 = Color(0xFF0D0D0D);           // 5% opacity

  /// Additional greys from lib
  static const Color greyColor = Color(0xFFB8B5C3);
  static const Color lightGreyColor = Color(0xFFF8F8F9);
  static const Color darkGreyColor = Color(0xFF1C1C25);

  // ===== NEUTRAL PALETTE =====
  static const Color neutralDarkest = Color(0xFF1F2937);        // Near black
  static const Color neutralDark = Color(0xFF374151);           // Dark gray
  static const Color neutralMedium = Color(0xFF6B7280);         // Medium gray
  static const Color neutralLight = Color(0xFFF3F4F6);          // Light gray
  static const Color neutralLightest = Color(0xFFFFFFFF);       // Pure white

  // Extended neutral palette
  static const Color neutral50 = Color(0xFFFAFAFA);             // Very light gray bg
  static const Color neutral100 = Color(0xFFF5F5F5);            // Light gray bg
  static const Color neutral200 = Color(0xFFE5E5E5);            // Light border
  static const Color neutral300 = Color(0xFFD4D4D4);            // Medium border
  static const Color neutral400 = Color(0xFFA3A3A3);            // Muted text
  static const Color neutral500 = Color(0xFF737373);            // Secondary text

  // ===== SURFACE COLORS =====
  static const Color surfacePrimary = Color(0xFFFFFFFF);        // White
  static const Color surfaceSecondary = Color(0xFFF9FAFB);      // Very light gray
  static const Color surfaceTertiary = Color(0xFFF3F4F6);       // Light gray
  static const Color surfaceOverlay = Color(0x40000000);        // 25% black overlay

  // ===== GRADIENTS =====
  /// Purple gradients matching lib design system
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7B61FF),  // Primary purple
      Color(0xFF6C56DD),  // Darker purple
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

  // Backward compatibility
  @Deprecated('Use purpleGradient instead')
  static const LinearGradient blueGradient = purpleGradient;
  @Deprecated('Use purpleGradient instead')
  static const LinearGradient goldGradient = purpleGradient;

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
      Color(0xFFEFECFF),  // Light purple
      Color(0xFF7B61FF),  // Primary purple
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

  static const List<BoxShadow> purpleShadow = [
    BoxShadow(
      color: Color(0x1A7B61FF),  // Purple with opacity
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  // Backward compatibility
  @Deprecated('Use purpleShadow instead')
  static const List<BoxShadow> goldShadow = purpleShadow;

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
  static const Color focusedOverlay = Color(0x157B61FF);        // Purple focus
  static const Color disabledOverlay = Color(0x40FFFFFF);

  // ===== BORDER COLORS =====
  static const Color borderPrimary = Color(0xFFE5E7EB);         // Light gray border
  static const Color borderSecondary = Color(0xFFF3F4F6);       // Very light border
  static const Color borderPurple = Color(0x607B61FF);          // Purple border
  static const Color borderTeal = Color(0x6014B8A6);            // Teal border

  // Backward compatibility
  @Deprecated('Use borderPurple instead')
  static const Color borderGold = borderPurple;

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
  static const Color storeVerifiedBadge = Color(0xFF7B61FF);    // Purple verified

  // ===== BACKWARD COMPATIBILITY =====
  static const Color backgroundLight = surfacePrimary;
  static const Color textPrimary = neutralDarkest;
  static const Color textSecondary = neutralMedium;
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color cardBackground = productCardBg;
  static const Color cardWhite = surfacePrimary;
  static const Color scaffoldBackground = Colors.white;  // Pure white background
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
  static const LinearGradient primaryGradient = purpleGradient;

  // Backward-compatible aliases
  static const Color primary = primaryColor;
  static const Color merchantStart = Color(0xFF7B61FF);         // Purple
  static const Color merchantEnd = Color(0xFF6C56DD);           // Darker purple
  static const Color userStart = Color(0xFFEFECFF);             // Light purple
  static const Color userEnd = Color(0xFF7B61FF);               // Purple

  // Category colors
  static const Color categoryElectronics = Color(0xFF7B61FF);   // Purple
  static const Color categoryFashion = Color(0xFFEC4899);
  static const Color categoryHome = Color(0xFF2ED573);          // Success green
  static const Color categorySports = Color(0xFFF59E0B);

  // Deal colors
  static const Color hotDealRed = Color(0xFFEF4444);

  // Shadow colors
  static const Color shadowColor = Color(0x15000000);
  static const Color shadowLight = Color(0x0D000000);           // Light shadow

  // Text colors
  static const Color textTertiary = Color(0xFF9CA3AF);          // Tertiary text

  // Notification colors
  static const Color notificationPurple = Color(0xFFEFECFF);    // Light purple
  static const Color notificationGreen = Color(0xFFD1FAE5);
  static const Color notificationYellow = Color(0xFFFEF3C7);

  // Backward compatibility
  @Deprecated('Use notificationPurple instead')
  static const Color notificationBlue = notificationPurple;

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
