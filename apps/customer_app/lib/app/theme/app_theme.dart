import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

export 'app_colors.dart';
export 'app_dimensions.dart';
export 'app_radius.dart';
export 'app_responsive.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

/// Global application theme configuration for Unique Basket Customer App.
///
/// Provides unified Material 3 Light and Dark themes with Montserrat typography,
/// centralized brand colors (#014D40, #E7F5F4, #8F4E00), and standardized component styles.
abstract final class AppTheme {
  /// Alias for [lightTheme].
  static ThemeData get light => lightTheme;

  /// Alias for [darkTheme].
  static ThemeData get dark => darkTheme;

  // ---------------------------------------------------------------------------
  // 1. LIGHT THEME
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderLight,
      shadow: Color(0x1A000000),
      scrim: AppColors.overlay,
    );

    final textTheme = AppTextStyles.createTextTheme(Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: textTheme,
      dividerColor: AppColors.divider,
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        toolbarHeight: AppDimensions.appBarHeight,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: AppDimensions.iconLg,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rMd,
          side: BorderSide(
            color: AppColors.cardBorder,
            width: AppDimensions.borderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      // Filled Button Theme (Primary)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, AppDimensions.buttonHeight),
          padding: AppSpacing.buttonPadding,
          shape: AppRadius.shapeMd,
          textStyle: AppTextStyles.button,
        ),
      ),
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, AppDimensions.buttonHeight),
          padding: AppSpacing.buttonPadding,
          shape: AppRadius.shapeMd,
          textStyle: AppTextStyles.button,
        ),
      ),
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          elevation: 0,
          minimumSize: const Size(0, AppDimensions.buttonHeight),
          side: const BorderSide(
            color: AppColors.primary,
            width: AppDimensions.focusedBorderWidth,
          ),
          padding: AppSpacing.buttonPadding,
          shape: AppRadius.shapeMd,
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
      ),
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, AppDimensions.buttonHeightSmall),
          padding: AppSpacing.buttonPaddingSmall,
          shape: AppRadius.shapeSm,
          textStyle: AppTextStyles.buttonSmall.copyWith(color: AppColors.primary),
        ),
      ),
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: AppSpacing.inputPadding,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.cardBorder,
            width: AppDimensions.borderWidth,
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.cardBorder,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.primary,
            width: AppDimensions.focusedBorderWidth,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.error,
            width: AppDimensions.focusedBorderWidth,
          ),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.borderLight,
            width: AppDimensions.borderWidth,
          ),
        ),
      ),
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: AppDimensions.dividerThickness,
        space: 1.0,
      ),
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rLg,
        ),
      ),
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        disabledColor: AppColors.borderLight,
        selectedColor: AppColors.secondary,
        secondarySelectedColor: AppColors.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.onSecondary),
        shape: AppRadius.shapeFull,
        side: BorderSide.none,
      ),
      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: AppDimensions.bottomNavHeight,
        indicatorColor: AppColors.secondary,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            );
          }
          return AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: AppDimensions.iconLg,
            );
          }
          return const IconThemeData(
            color: AppColors.textTertiary,
            size: AppDimensions.iconLg,
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. DARK THEME
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.dividerDark,
      shadow: Color(0x66000000),
      scrim: AppColors.overlayDark,
    );

    final textTheme = AppTextStyles.createTextTheme(Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.primary,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: textTheme,
      dividerColor: AppColors.dividerDark,
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        toolbarHeight: AppDimensions.appBarHeight,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimaryDark,
          size: AppDimensions.iconLg,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rMd,
          side: BorderSide(
            color: AppColors.cardBorderDark,
            width: AppDimensions.borderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      // Filled Button Theme (Primary)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, AppDimensions.buttonHeight),
          padding: AppSpacing.buttonPadding,
          shape: AppRadius.shapeMd,
          textStyle: AppTextStyles.button,
        ),
      ),
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, AppDimensions.buttonHeight),
          padding: AppSpacing.buttonPadding,
          shape: AppRadius.shapeMd,
          textStyle: AppTextStyles.button,
        ),
      ),
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          elevation: 0,
          minimumSize: const Size(0, AppDimensions.buttonHeight),
          side: const BorderSide(
            color: AppColors.primary,
            width: AppDimensions.focusedBorderWidth,
          ),
          padding: AppSpacing.buttonPadding,
          shape: AppRadius.shapeMd,
          textStyle: AppTextStyles.button.copyWith(color: AppColors.secondary),
        ),
      ),
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          minimumSize: const Size(0, AppDimensions.buttonHeightSmall),
          padding: AppSpacing.buttonPaddingSmall,
          shape: AppRadius.shapeSm,
          textStyle: AppTextStyles.buttonSmall.copyWith(color: AppColors.secondary),
        ),
      ),
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: AppSpacing.inputPadding,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMutedDark),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.cardBorderDark,
            width: AppDimensions.borderWidth,
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.cardBorderDark,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.primary,
            width: AppDimensions.focusedBorderWidth,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.error,
            width: AppDimensions.focusedBorderWidth,
          ),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(
            color: AppColors.borderDark,
            width: AppDimensions.borderWidth,
          ),
        ),
      ),
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: AppDimensions.dividerThickness,
        space: 1.0,
      ),
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rLg,
        ),
      ),
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        disabledColor: AppColors.borderDark,
        selectedColor: AppColors.primaryContainer,
        secondarySelectedColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimaryDark),
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.onPrimary),
        shape: AppRadius.shapeFull,
        side: BorderSide.none,
      ),
      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        height: AppDimensions.bottomNavHeight,
        indicatorColor: AppColors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            );
          }
          return AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiaryDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.secondary,
              size: AppDimensions.iconLg,
            );
          }
          return const IconThemeData(
            color: AppColors.textTertiaryDark,
            size: AppDimensions.iconLg,
          );
        }),
      ),
    );
  }
}
