import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  static TextStyle _base({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color color = AppColors.textPrimary,
    double? height,
  }) {
    return GoogleFonts.cairo(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height ?? 1.4,
      letterSpacing: 0,
    );
  }

  // Headings
  static TextStyle get h1 => _base(size: 28, weight: FontWeight.w700);
  static TextStyle get h2 => _base(size: 22, weight: FontWeight.w700);
  static TextStyle get h3 => _base(size: 18, weight: FontWeight.w600);
  static TextStyle get h4 => _base(size: 16, weight: FontWeight.w600);

  // Body Text
  static TextStyle get bodyLarge => _base(size: 16, weight: FontWeight.w400);
  static TextStyle get bodyMedium => _base(size: 14, weight: FontWeight.w400);
  static TextStyle get bodySmall => _base(size: 12, weight: FontWeight.w400, color: AppColors.textSecondary);

  // Special Styles
  static TextStyle get buttonText => _base(size: 14, weight: FontWeight.w600, color: Colors.white);
  static TextStyle get priceText => _base(size: 16, weight: FontWeight.w700, color: AppColors.primaryDeep);
  static TextStyle get oldPriceText => _base(size: 12, color: AppColors.textHint).copyWith(decoration: TextDecoration.lineThrough);
  static TextStyle get categoryLabel => _base(size: 12, weight: FontWeight.w600);
  static TextStyle get ratingText => _base(size: 12, weight: FontWeight.w600, color: AppColors.ratingYellow);
  static TextStyle get hintText => _base(size: 14, color: AppColors.textHint);
  static TextStyle get linkText => _base(size: 14, weight: FontWeight.w600, color: AppColors.primaryBlue);
  static TextStyle get badgeText => _base(size: 10, weight: FontWeight.w600, color: Colors.white);
  static TextStyle get timerText => _base(size: 14, weight: FontWeight.w700, color: Colors.white);
  static TextStyle get discountText => _base(size: 11, weight: FontWeight.w700, color: Colors.white);
  static TextStyle get promoTitle => _base(size: 20, weight: FontWeight.w700, color: Colors.white);
  static TextStyle get promoSubtitle => _base(size: 12, color: const Color(0xB3FFFFFF));
  static TextStyle get navLabelActive => _base(size: 11, weight: FontWeight.w600, color: AppColors.primaryBlue);
  static TextStyle get navLabelInactive => _base(size: 11, weight: FontWeight.w500, color: AppColors.textHint);

  // Form labels
  static TextStyle get label => _base(size: 14, weight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle get inputText => _base(size: 14, weight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle get inputHint => _base(size: 14, weight: FontWeight.w400, color: AppColors.textHint);

  // Notification styles
  static TextStyle get notificationTitle => _base(size: 14, weight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get notificationBody => _base(size: 12, weight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle get notificationTime => _base(size: 11, weight: FontWeight.w400, color: AppColors.textHint);

  // Tab styles
  static TextStyle get tabActive => _base(size: 14, weight: FontWeight.w600, color: AppColors.primaryBlue);
  static TextStyle get tabInactive => _base(size: 14, weight: FontWeight.w500, color: AppColors.textSecondary);

  // Stats
  static TextStyle get statValue => _base(size: 18, weight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle get statLabel => _base(size: 12, weight: FontWeight.w400, color: AppColors.textSecondary);

  // Caption (small text)
  static TextStyle get caption => _base(size: 10, weight: FontWeight.w400, color: AppColors.textHint);
}
