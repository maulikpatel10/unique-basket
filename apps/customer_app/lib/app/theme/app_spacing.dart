import 'package:flutter/material.dart';

class AppSpacing {
  // Spacing constants
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double sm = 8.0;
  static const double m = 12.0;
  static const double md = 16.0;
  static const double l = 20.0;
  static const double lg = 24.0;
  static const double xl = 28.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;

  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusFull = 999.0;

  // Common Paddings
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0);

  // Common Border Radius Objects
  static final BorderRadius roundedSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius roundedMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius roundedLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius roundedFull = BorderRadius.circular(radiusFull);
}
