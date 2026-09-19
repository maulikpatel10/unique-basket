import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Global box shadow elevation tokens for Unique Basket Customer App.
///
/// Provides subtle, modern, multi-layered elevation shadows for cards,
/// floating elements, dialogs, and brand CTA buttons.
abstract final class AppShadows {
  // ---------------------------------------------------------------------------
  // 1. NO SHADOW
  // ---------------------------------------------------------------------------
  static const List<BoxShadow> none = [];

  // ---------------------------------------------------------------------------
  // 2. LIGHT THEME SHADOWS
  // ---------------------------------------------------------------------------
  /// Subtle elevation for cards, list items, and input focus (2-4dp equivalent).
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000), // ~4% black
      blurRadius: 4.0,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x08000000), // ~3% black
      blurRadius: 8.0,
      offset: Offset(0, 2),
    ),
  ];

  /// Medium elevation for dropdowns, popovers, and sticky headers (6-8dp equivalent).
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F000000), // ~6% black
      blurRadius: 10.0,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000), // ~4% black
      blurRadius: 16.0,
      offset: Offset(0, 6),
    ),
  ];

  /// Strong elevation for modals, bottom sheets, and floating action buttons (12-16dp equivalent).
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x14000000), // ~8% black
      blurRadius: 20.0,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0F000000), // ~6% black
      blurRadius: 30.0,
      offset: Offset(0, 12),
    ),
  ];

  /// Brand-tinted elevation for primary action buttons.
  static final List<BoxShadow> primary = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.25),
      blurRadius: 16.0,
      offset: const Offset(0, 6),
    ),
  ];

  /// Tertiary-tinted elevation for special promotion / amber badges.
  static final List<BoxShadow> tertiary = [
    BoxShadow(
      color: AppColors.tertiary.withValues(alpha: 0.25),
      blurRadius: 16.0,
      offset: const Offset(0, 6),
    ),
  ];

  // ---------------------------------------------------------------------------
  // 3. DARK THEME SHADOWS
  // ---------------------------------------------------------------------------
  static const List<BoxShadow> smDark = [
    BoxShadow(
      color: Color(0x33000000), // 20% black
      blurRadius: 4.0,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> mdDark = [
    BoxShadow(
      color: Color(0x55000000), // 33% black
      blurRadius: 12.0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lgDark = [
    BoxShadow(
      color: Color(0x77000000), // ~46% black
      blurRadius: 24.0,
      offset: Offset(0, 8),
    ),
  ];
}
