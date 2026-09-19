import 'package:flutter/material.dart';

/// Global corner radius tokens for Unique Basket Customer App.
///
/// Provides both scalar double values, const BorderRadius objects,
/// and const Outlined/RoundedRectangleBorder shapes.
abstract final class AppRadius {
  // ---------------------------------------------------------------------------
  // 1. SCALAR RADIUS VALUES
  // ---------------------------------------------------------------------------
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  // ---------------------------------------------------------------------------
  // 2. CONST BORDER RADIUS OBJECTS
  // ---------------------------------------------------------------------------
  static const BorderRadius rNone = BorderRadius.zero;
  static const BorderRadius rXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius rFull = BorderRadius.all(Radius.circular(full));

  // ---------------------------------------------------------------------------
  // 3. CONST ROUNDED RECTANGLE BORDER SHAPES
  // ---------------------------------------------------------------------------
  static const RoundedRectangleBorder shapeXs = RoundedRectangleBorder(borderRadius: rXs);
  static const RoundedRectangleBorder shapeSm = RoundedRectangleBorder(borderRadius: rSm);
  static const RoundedRectangleBorder shapeMd = RoundedRectangleBorder(borderRadius: rMd);
  static const RoundedRectangleBorder shapeLg = RoundedRectangleBorder(borderRadius: rLg);
  static const RoundedRectangleBorder shapeXl = RoundedRectangleBorder(borderRadius: rXl);
  static const RoundedRectangleBorder shapeFull = RoundedRectangleBorder(borderRadius: rFull);
}
