import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme => lightThemeFor();

  static ThemeData lightThemeFor([Locale? locale]) {
    final fontFamily = AppTypography.fontFamily(locale);

    return ThemeData(
      fontFamily: fontFamily,
      primaryColor: AppColors.primaryColor,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      useMaterial3: true,
      textTheme: _buildTextTheme(locale),

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryColor,
        primary: AppColors.primaryColor,
        secondary: AppColors.accentTeal,
        surface: AppColors.surfacePrimary,
        error: AppColors.errorRed,
        brightness: Brightness.light,
      ),

      // Clean AppBar — Travo style (white, flat, bold title)
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: AppColors.blackColor, size: 22),
        titleTextStyle: AppTypography.textStyle(
          locale,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.blackColor,
        ),
        toolbarHeight: 56,
        centerTitle: true,
      ),

      // Card Theme — Modern Material Design 3 style
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: AppColors.primaryColor.withValues(alpha: 0.08),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
      ),

      // Input Design (matching screenshots - outlined style)
      inputDecorationTheme: InputDecorationTheme(
        filled: false, // No fill - clean outlined style
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(24), // Pill shape like screenshots
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
              color: AppColors.blackColor20, width: 1.5), // Light border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
              color: AppColors.primaryColor, width: 2), // Purple on focus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: AppTypography.textStyle(
          locale,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.greyColor,
        ),
      ),

      // Button Themes (pill-shaped like screenshots)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor, // Purple background
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.primaryColor.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize:
              const Size(double.infinity, 56), // Accessibility-friendly height
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28), // Pill shape
          ),
          textStyle: AppTypography.textStyle(
            locale,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
          // Add smooth press animation
          animationDuration: const Duration(milliseconds: 200),
        ).copyWith(
          // Hover effect for web/desktop
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),

      // Outlined Button Theme (pill-shaped)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: AppColors.primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27), // Pill shape
          ),
          textStyle: AppTypography.textStyle(
            locale,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryColor, // Purple text
          textStyle: AppTypography.textStyle(
            locale,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Bottom Navigation (matching lib design system)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryColor, // Purple selected
        unselectedItemColor: Colors.transparent, // Transparent unselected
        type: BottomNavigationBarType.fixed, // Fixed type for 5 items
        elevation: 0,
        selectedLabelStyle: AppTypography.textStyle(
          locale,
          fontSize: 12, // 12px font size
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.textStyle(
          locale,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Bottom App Bar
      bottomAppBarTheme: BottomAppBarThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryColor,
        elevation: 4,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        extendedTextStyle: AppTypography.textStyle(
          locale,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.borderPrimary,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSecondary,
        selectedColor: AppColors.primaryLightShade,
        disabledColor: AppColors.surfaceTertiary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderPrimary),
        ),
        labelStyle: AppTypography.textStyle(
          locale,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: AppTypography.textStyle(
          locale,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryColor,
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTypography.textStyle(
          locale,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.textStyle(
          locale,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 18,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        menuPadding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
              color: AppColors.borderPrimary.withValues(alpha: 0.95)),
        ),
        textStyle: AppTypography.textStyle(
          locale,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        thumbIcon: WidgetStateProperty.all(null),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primaryColor.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryColor;
          }
          return const Color(0xFFE8E2FB);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryColor;
          }
          return const Color(0xFFD9D1F7);
        }),
        trackOutlineWidth: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return 0;
          }
          return 1.2;
        }),
      ),

      // Checkbox Theme (from lib design system)
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(Colors.white), // White checkmark
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryColor;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6), // Rounded corners
        ),
        side: BorderSide(color: AppColors.whiteColor40),
      ),
    );
  }

  // Typography System
  static TextTheme _buildTextTheme(Locale? locale) {
    return TextTheme(
      displayLarge: AppTypography.textStyle(
        locale,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displayMedium: AppTypography.textStyle(
        locale,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      displaySmall: AppTypography.textStyle(
        locale,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineLarge: AppTypography.textStyle(
        locale,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: AppTypography.textStyle(
        locale,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: AppTypography.textStyle(
        locale,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleLarge: AppTypography.textStyle(
        locale,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: AppTypography.textStyle(
        locale,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleSmall: AppTypography.textStyle(
        locale,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      bodyLarge: AppTypography.textStyle(
        locale,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: AppTypography.textStyle(
        locale,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      bodySmall: AppTypography.textStyle(
        locale,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: AppTypography.textStyle(
        locale,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      labelMedium: AppTypography.textStyle(
        locale,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: AppTypography.textStyle(
        locale,
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
      ),
    );
  }

  // Animation Durations (Enhanced for better UX)
  static const Duration microAnimation = Duration(milliseconds: 100);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 350);

  // Animation Curves (Modern UX standards)
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
  static const Curve deceleratedCurve = Curves.easeOut;
  static const Curve acceleratedCurve = Curves.easeIn;
  static const Curve bounceCurve = Curves.elasticOut;

  // Border Radius (Enhanced with more options)
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius mediumRadius =
      BorderRadius.all(Radius.circular(12));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius xxlRadius = BorderRadius.all(Radius.circular(28));
  static const BorderRadius circularRadius =
      BorderRadius.all(Radius.circular(999));

  // Spacing System (8px base grid)
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing28 = 28.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // Icon Sizes (Enhanced system)
  static const double iconTiny = 12.0;
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  static const double iconHuge = 64.0;

  // Elevation System (Material Design 3)
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 4.0;
  static const double elevation4 = 6.0;
  static const double elevation5 = 8.0;

  // Touch Target Sizes (Accessibility - minimum 48x48dp)
  static const double minTouchTarget = 48.0;
  static const double recommendedTouchTarget = 56.0;

  // Transition Configurations
  static PageTransitionsTheme get pageTransitionsTheme =>
      const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      );
}
