import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Global Typography system for Unique Basket Customer App.
///
/// Uses the Montserrat font family throughout for a modern, clean, premium feel.
/// Provides a standard Material 3 type scale + application semantic styles.
abstract final class AppTextStyles {
  // ---------------------------------------------------------------------------
  // FONT FAMILY DEFINITION
  // ---------------------------------------------------------------------------
  static const String fontFamily = 'Montserrat';

  // ---------------------------------------------------------------------------
  // 1. DISPLAY (Large promotional / hero text)
  // ---------------------------------------------------------------------------
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.12,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.0,
    height: 1.16,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    height: 1.22,
    color: AppColors.textPrimary,
  );

  // ---------------------------------------------------------------------------
  // 2. HEADLINE (Screen headers, section highlights)
  // ---------------------------------------------------------------------------
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.29,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    height: 1.33,
    color: AppColors.textPrimary,
  );

  // ---------------------------------------------------------------------------
  // 3. TITLE (Card headers, list headers, app bar)
  // ---------------------------------------------------------------------------
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    height: 1.27,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  // ---------------------------------------------------------------------------
  // 4. BODY (Main readable content, descriptions)
  // ---------------------------------------------------------------------------
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  // ---------------------------------------------------------------------------
  // 5. LABEL (Buttons, tags, badges, input labels)
  // ---------------------------------------------------------------------------
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    color: AppColors.textTertiary,
  );

  // ---------------------------------------------------------------------------
  // 6. APPLICATION SEMANTIC STYLES
  // ---------------------------------------------------------------------------
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.33,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.23,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle price = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle priceLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.primary,
  );

  static const TextStyle priceSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    height: 1.23,
    color: AppColors.textSecondary,
  );

  static const TextStyle priceMrp = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    decoration: TextDecoration.lineThrough,
    color: AppColors.textMuted,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.27,
    color: AppColors.textMuted,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    height: 1.6,
    color: AppColors.textTertiary,
  );

  // Legacy convenience aliases mapping directly to the new hierarchy
  static const TextStyle h1 = headlineLarge;
  static const TextStyle h2 = headlineMedium;
  static const TextStyle h3 = headlineSmall;
  static const TextStyle subtitle1 = titleMedium;
  static const TextStyle subtitle2 = titleSmall;

  // ---------------------------------------------------------------------------
  // 7. MATERIAL 3 TEXT THEME BUILDER
  // ---------------------------------------------------------------------------
  /// Builds a complete Material 3 TextTheme aligned with Montserrat and the brand typography scale.
  static TextTheme createTextTheme([Brightness brightness = Brightness.light]) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final tertiaryColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiary;

    return TextTheme(
      displayLarge: displayLarge.copyWith(color: primaryColor),
      displayMedium: displayMedium.copyWith(color: primaryColor),
      displaySmall: displaySmall.copyWith(color: primaryColor),
      headlineLarge: headlineLarge.copyWith(color: primaryColor),
      headlineMedium: headlineMedium.copyWith(color: primaryColor),
      headlineSmall: headlineSmall.copyWith(color: primaryColor),
      titleLarge: titleLarge.copyWith(color: primaryColor),
      titleMedium: titleMedium.copyWith(color: primaryColor),
      titleSmall: titleSmall.copyWith(color: primaryColor),
      bodyLarge: bodyLarge.copyWith(color: primaryColor),
      bodyMedium: bodyMedium.copyWith(color: primaryColor),
      bodySmall: bodySmall.copyWith(color: secondaryColor),
      labelLarge: labelLarge.copyWith(color: primaryColor),
      labelMedium: labelMedium.copyWith(color: secondaryColor),
      labelSmall: labelSmall.copyWith(color: tertiaryColor),
    );
  }

  /// Optional helper to apply GoogleFonts Montserrat styling dynamically.
  static TextTheme applyGoogleFonts(TextTheme base) {
    return GoogleFonts.montserratTextTheme(base);
  }
}
