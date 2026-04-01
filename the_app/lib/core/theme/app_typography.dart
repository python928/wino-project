import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static const String arabicFontName = 'Alexandria';
  static const String latinFontName = 'Sora';

  static bool isArabic(Locale? locale) =>
      locale?.languageCode.toLowerCase() == 'ar';

  static TextStyle textStyle(
    Locale? locale, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final baseBuilder =
        isArabic(locale) ? GoogleFonts.alexandria : GoogleFonts.sora;
    return baseBuilder(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static String fontFamily(Locale? locale) {
    return textStyle(locale).fontFamily ?? latinFontName;
  }
}
