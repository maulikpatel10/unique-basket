import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  static final List<BoxShadow> sm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4.0,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> md = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 10.0,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> lg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20.0,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> primary = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.2),
      blurRadius: 16.0,
      offset: const Offset(0, 6),
    ),
  ];
}
