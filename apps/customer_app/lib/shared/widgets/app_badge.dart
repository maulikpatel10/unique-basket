import 'package:flutter/material.dart';
import '../../app/theme/app_text_styles.dart';

enum BadgeVariant { discount, stock, status, tag }

/// Canonical Configurable Badge component for UNIQUE BASKET.
class AppBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final bool? isDark;

  const AppBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.discount,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.fontSize,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderRadius radius;
    EdgeInsets resolvedPadding;
    double resolvedFontSize = fontSize ?? 9.5;
    FontWeight fontWeight = FontWeight.w700;
    List<BoxShadow>? shadows;

    switch (variant) {
      case BadgeVariant.discount:
        bg = backgroundColor ??
            (text.toLowerCase().contains('local')
                ? const Color(0xFF854D0E)
                : const Color(0xFF9E4B00));
        fg = textColor ?? Colors.white;
        radius = BorderRadius.circular(5.0);
        resolvedPadding = padding as EdgeInsets? ??
            const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.5);
        break;

      case BadgeVariant.stock:
        bg = backgroundColor ?? const Color(0xFF014D40);
        fg = textColor ?? Colors.white;
        radius = BorderRadius.circular(999);
        resolvedFontSize = fontSize ?? 10.0;
        fontWeight = FontWeight.w800;
        resolvedPadding = padding as EdgeInsets? ??
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.5);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
        break;

      case BadgeVariant.status:
        bg = backgroundColor ?? const Color(0xFFE6F4EA);
        fg = textColor ?? const Color(0xFF014D40);
        radius = BorderRadius.circular(999);
        resolvedFontSize = fontSize ?? 11.0;
        resolvedPadding = padding as EdgeInsets? ??
            const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0);
        break;

      case BadgeVariant.tag:
        bg = backgroundColor ?? const Color(0xFFF1F5F9);
        fg = textColor ?? const Color(0xFF0F172A);
        radius = BorderRadius.circular(6.0);
        resolvedFontSize = fontSize ?? 11.0;
        resolvedPadding = padding as EdgeInsets? ??
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0);
        break;
    }

    return Container(
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        boxShadow: shadows,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: resolvedFontSize,
          fontWeight: fontWeight,
          letterSpacing: 0.2,
          fontFamily: AppTextStyles.fontFamily,
        ),
      ),
    );
  }
}
