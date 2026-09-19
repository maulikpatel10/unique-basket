import 'package:flutter/material.dart';

/// Breakpoint constants and responsive layout constraints for Unique Basket Customer App.
///
/// Provides unified device detection, bounded scaling limits, and content boundaries
/// based on the approved 390 × 844 dp Figma design reference.
abstract final class AppBreakpoints {
  /// Maximum width for compact / small phones (e.g. older iPhones, compact Androids).
  static const double smallPhone = 360.0;

  /// Maximum width for standard phones before tablet classification.
  static const double phone = 600.0;

  /// Minimum width for tablet / large screen layouts.
  static const double tablet = 600.0;

  /// Minimum width for desktop / wide screens.
  static const double desktop = 1024.0;

  /// Height threshold below which viewports are categorized as vertically short/compact.
  static const double shortScreen = 680.0;

  /// Max content width for single-column auth, profile, and address forms on tablets.
  static const double maxFormWidth = 440.0;

  /// Max content width for legal, terms, and privacy documentation on tablets.
  static const double maxLegalWidth = 600.0;

  /// Max content width for main catalog, product grids, and dashboards on tablets.
  static const double maxContentWidth = 720.0;
}

/// Centralized, context-bound responsive engine for Unique Basket Customer App.
///
/// Reference Baseline: 390.0 × 844.0 dp (Figma design baseline).
///
/// Features:
/// - 100% Deterministic & Context-Bound: Queries the exact [BuildContext] / [MediaQueryData]
///   without any global mutable state or assumptions about single views.
/// - Strictly Bounded Clamping: Prevents micro-elements on small phones (<360dp) and
///   grotesquely oversized elements on tablets (>=600dp).
/// - Accessibility First: Text scaling (.sp) natively routes through Flutter's [TextScaler].
class AppResponsive {
  /// Baseline design width (Figma viewport).
  static const double designWidth = 390.0;

  /// Baseline design height (Figma viewport).
  static const double designHeight = 844.0;

  // Clamping constants
  static const double minWidthScale = 0.85;
  static const double maxWidthScale = 1.20;
  static const double minHeightScale = 0.80;
  static const double maxHeightScale = 1.20;
  static const double minFontScale = 0.90;
  static const double maxFontScale = 1.15;

  final BuildContext context;

  const AppResponsive(this.context);

  /// Current device screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(context).width;

  /// Current device screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(context).height;

  /// Device pixel ratio.
  double get devicePixelRatio => MediaQuery.devicePixelRatioOf(context);

  /// Device text scale factor for accessibility.
  double get textScaleFactor => MediaQuery.textScalerOf(context).scale(1.0);

  /// Safe area top padding.
  double get topPadding => MediaQuery.paddingOf(context).top;

  /// Safe area bottom padding.
  double get bottomPadding => MediaQuery.paddingOf(context).bottom;

  /// True if screen width is strictly smaller than small phone width (< 360dp).
  bool get isSmallPhone => screenWidth < AppBreakpoints.smallPhone;

  /// True if phone (< 600dp).
  bool get isPhone => screenWidth < AppBreakpoints.tablet;

  /// True if tablet (>= 600dp and < 1024dp).
  bool get isTablet => screenWidth >= AppBreakpoints.tablet && screenWidth < AppBreakpoints.desktop;

  /// True if desktop (>= 1024dp).
  bool get isDesktop => screenWidth >= AppBreakpoints.desktop;

  /// True if tablet or larger (>= 600dp).
  bool get isTabletOrLarger => screenWidth >= AppBreakpoints.tablet;

  /// True if screen is compact in width (< 360dp) OR short in height (< 680dp).
  bool get isCompact => isSmallPhone || screenHeight < AppBreakpoints.shortScreen;

  /// Returns orientation.
  Orientation get orientation => MediaQuery.orientationOf(context);
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;

  // ---------------------------------------------------------------------------
  // CONTEXT-BOUND SCALING METHODS
  // ---------------------------------------------------------------------------

  /// General-purpose responsive scaling (.r) from the 390dp design width.
  ///
  /// Uses screenWidth / 390.0 clamped to [0.85, 1.20].
  /// Best for: General dimensions, icon sizes, component padding, and corner radius.
  /// DO NOT use for: 1.0dp borders, minimum 48dp touch targets, or fluid layouts (Expanded).
  double r(num value) => scaleWidth(value.toDouble());

  /// Width-specific responsive scaling (.w).
  ///
  /// Uses screenWidth / 390.0 clamped to [0.85, 1.20].
  /// Best for: Fixed horizontal spacing, specific custom card/modal widths.
  double w(num value) => scaleWidth(value.toDouble());

  /// Height-specific responsive scaling (.h).
  ///
  /// Uses screenHeight / 844.0 clamped to [0.80, 1.20].
  /// Best for: Genuine viewport-relative vertical gaps and banner heights.
  double h(num value) => scaleHeight(value.toDouble());

  /// Controlled font scaling (.sp).
  ///
  /// Scales base font size with width (clamped 0.90x - 1.15x), then applies
  /// the active [TextScaler] for full OS accessibility compliance.
  double sp(num value) {
    if (value == 0) return 0.0;
    final fontDimensionScale = (screenWidth / designWidth).clamp(minFontScale, maxFontScale);
    final scaledBase = value.toDouble() * fontDimensionScale;
    return MediaQuery.textScalerOf(context).scale(scaledBase);
  }

  /// Returns a bounded scaled dimension proportional to the screen width.
  double scaleWidth(
    double size, {
    double minScale = minWidthScale,
    double maxScale = maxWidthScale,
  }) {
    if (size == 0) return 0.0;
    final scale = (screenWidth / designWidth).clamp(minScale, maxScale);
    return (size * scale).roundToDouble();
  }

  /// Returns a bounded scaled dimension proportional to the screen height.
  double scaleHeight(
    double size, {
    double minScale = minHeightScale,
    double maxScale = maxHeightScale,
  }) {
    if (size == 0) return 0.0;
    final scale = (screenHeight / designHeight).clamp(minScale, maxScale);
    return (size * scale).roundToDouble();
  }

  /// Scaled dimension that strictly respects accessibility minimums (never scales below minTouchTarget).
  double scaleTouchTarget(double size) {
    return scaleWidth(size, minScale: 1.0, maxScale: maxWidthScale);
  }

  /// Returns a width calculated as a fraction of total screen width (e.g. 0.5 = 50% width).
  double widthPercent(double factor) => screenWidth * factor;

  /// Returns a height calculated as a fraction of total screen height (e.g. 0.25 = 25% height).
  double heightPercent(double factor) => screenHeight * factor;
}

/// Authoritative context-bound responsive extension on [BuildContext].
///
/// All responsive dimension calculations MUST route through [BuildContext]
/// to guarantee view-safety, correct orientation handling, and multi-window correctness.
///
/// Examples:
/// ```dart
/// final logoWidth = context.r(239);
/// final padding = context.w(16);
/// final gap = context.h(24);
/// final fontSize = context.sp(16);
/// ```
extension AppResponsiveContext on BuildContext {
  /// Responsive helper instance for the current context.
  AppResponsive get responsive => AppResponsive(this);

  /// Device screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Device screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Safe area top padding.
  double get safeAreaTop => MediaQuery.paddingOf(this).top;

  /// Safe area bottom padding.
  double get safeAreaBottom => MediaQuery.paddingOf(this).bottom;

  /// True if small phone (< 360dp).
  bool get isSmallPhone => screenWidth < AppBreakpoints.smallPhone;

  /// True if phone (< 600dp).
  bool get isPhone => screenWidth < AppBreakpoints.tablet;

  /// True if tablet (>= 600dp and < 1024dp).
  bool get isTablet => screenWidth >= AppBreakpoints.tablet && screenWidth < AppBreakpoints.desktop;

  /// True if desktop (>= 1024dp).
  bool get isDesktop => screenWidth >= AppBreakpoints.desktop;

  /// True if tablet or larger (>= 600dp).
  bool get isTabletOrLarger => screenWidth >= AppBreakpoints.tablet;

  /// True if screen is compact (< 360dp width or < 680dp height).
  bool get isCompact => isSmallPhone || screenHeight < AppBreakpoints.shortScreen;

  /// Calculates a width based on a screen fraction (0.0 - 1.0).
  double responsiveWidth(double factor) => screenWidth * factor;

  /// Calculates a height based on a screen fraction (0.0 - 1.0).
  double responsiveHeight(double factor) => screenHeight * factor;

  /// General-purpose responsive scaling (.r) bound to this [BuildContext].
  double r(num value) => responsive.r(value);

  /// Width-specific responsive scaling (.w) bound to this [BuildContext].
  double w(num value) => responsive.w(value);

  /// Height-specific responsive scaling (.h) bound to this [BuildContext].
  double h(num value) => responsive.h(value);

  /// Controlled font scaling (.sp) bound to this [BuildContext] (accessibility aware).
  double sp(num value) => responsive.sp(value);

  /// Bounded scaling for a dimension (backward-compatible method).
  double scale(double size, {double minScale = AppResponsive.minWidthScale, double maxScale = AppResponsive.maxWidthScale}) {
    return responsive.scaleWidth(size, minScale: minScale, maxScale: maxScale);
  }
}
