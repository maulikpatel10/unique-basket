import 'package:flutter/material.dart';

/// Global brand and semantic color tokens for Unique Basket Customer App.
///
/// Official Brand Identity:
/// - Primary: #014D40 (Deep Pine Green)
/// - Secondary: #E7F5F4 (Soft Mint/Ice Green)
/// - Tertiary: #8F4E00 (Warm Amber/Bronze)

abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // 1. BRAND TOKENS
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF014D40);
  static const Color primaryContainer = Color(0xFF036957);
  static const Color primaryLight = Color(0xFF1B6B5D);
  static const Color primaryUltraLight = Color(0xFFD8EFEA);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFFE7F5F4);
  static const Color secondaryContainer = Color(0xFFCDECE9);
  static const Color secondaryDark = Color(0xFFB5DDD8);
  static const Color onSecondary = Color(0xFF014D40);
  static const Color onSecondaryContainer = Color(0xFF00201A);

  static const Color tertiary = Color(0xFF8F4E00);
  static const Color tertiaryContainer = Color(0xFFFFDCC1);
  static const Color tertiaryLight = Color(0xFFB86806);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF2E1500);

  // ---------------------------------------------------------------------------
  // 2. SURFACES & BACKGROUNDS (LIGHT)
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFFF7FAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDF4F3);
  static const Color surfaceContainer = Color(0xFFE5EFEB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color overlay = Color(0x66000000);

  // ---------------------------------------------------------------------------
  // 3. SURFACES & BACKGROUNDS (DARK)
  // ---------------------------------------------------------------------------
  static const Color backgroundDark = Color(0xFF0A1312);
  static const Color surfaceDark = Color(0xFF111D1B);
  static const Color surfaceVariantDark = Color(0xFF192A27);
  static const Color surfaceContainerDark = Color(0xFF203532);
  static const Color cardDark = Color(0xFF142220);
  static const Color overlayDark = Color(0x99000000);

  // ---------------------------------------------------------------------------
  // 4. TEXT & TYPOGRAPHY COLORS (LIGHT)
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF0E1A18);
  static const Color textSecondary = Color(0xFF475E5A);
  static const Color textTertiary = Color(0xFF76918D);
  static const Color textMuted = Color(0xFF8FA7A3);
  static const Color textDisabled = Color(0xFFB3C5C2);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF014D40);
  static const Color textOnTertiary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFF5FAF9);

  // ---------------------------------------------------------------------------
  // 5. TEXT & TYPOGRAPHY COLORS (DARK)
  // ---------------------------------------------------------------------------
  static const Color textPrimaryDark = Color(0xFFF0F7F6);
  static const Color textSecondaryDark = Color(0xFFA8BFBC);
  static const Color textTertiaryDark = Color(0xFF7A9692);
  static const Color textMutedDark = Color(0xFF5B7571);
  static const Color textDisabledDark = Color(0xFF405652);

  // ---------------------------------------------------------------------------
  // 6. BORDERS & DIVIDERS
  // ---------------------------------------------------------------------------
  static const Color border = Color(0xFFD0DFDC);
  static const Color borderLight = Color(0xFFE6EFEB);
  static const Color borderDark = Color(0xFF253936);
  static const Color cardBorder = Color(0xFFDDE8E5);
  static const Color cardBorderDark = Color(0xFF223431);
  static const Color divider = Color(0xFFE2ECEA);
  static const Color dividerDark = Color(0xFF1E302D);

  // ---------------------------------------------------------------------------
  // 7. STATUS & FEEDBACK COLORS
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF198754);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFD1F2DF);
  static const Color onSuccessContainer = Color(0xFF063A21);

  static const Color warning = Color(0xFFD97706);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF451A03);

  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color info = Color(0xFF0284C7);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFE0F2FE);
  static const Color onInfoContainer = Color(0xFF082F49);

  // ---------------------------------------------------------------------------
  // 8. UTILITY & SHIMMER
  // ---------------------------------------------------------------------------
  static const Color shimmerBase = Color(0xFFE2EBE9);
  static const Color shimmerHighlight = Color(0xFFF4F9F8);
  static const Color shimmerBaseDark = Color(0xFF1E2E2B);
  static const Color shimmerHighlightDark = Color(0xFF2A3F3B);
}
