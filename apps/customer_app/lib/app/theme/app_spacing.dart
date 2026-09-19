import 'package:flutter/material.dart';

/// Global spacing scale and reusable EdgeInsets tokens for Unique Basket Customer App.
///
/// All layouts must reference these standardized tokens instead of ad-hoc numbers.
abstract final class AppSpacing {
  // ---------------------------------------------------------------------------
  // 1. SCALAR SPACING TOKENS (8-pt aligned grid)
  // ---------------------------------------------------------------------------
  static const double none = 0.0;
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double xxxl = 48.0;

  // ---------------------------------------------------------------------------
  // 2. SEMANTIC LAYOUT SPACING
  // ---------------------------------------------------------------------------
  static const double screenHorizontal = 16.0;
  static const double screenVertical = 16.0;
  static const double section = 24.0;
  static const double card = 16.0;
  static const double field = 12.0;
  static const double button = 16.0;
  static const double listItem = 12.0;
  static const double inlineGap = 8.0;

  // ---------------------------------------------------------------------------
  // 3. REUSABLE EDGEINSETS OBJECTS
  // ---------------------------------------------------------------------------
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
    vertical: screenVertical,
  );

  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(
    vertical: screenVertical,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(card);

  static const EdgeInsets cardPaddingDense = EdgeInsets.all(12.0);

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 14.0,
  );

  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: 14.0,
    vertical: 8.0,
  );

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 14.0,
  );

  static const EdgeInsets dialogPadding = EdgeInsets.all(24.0);

  static const EdgeInsets bottomSheetPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );

  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
}
