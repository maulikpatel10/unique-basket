import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';

enum ButtonVariant { primary, secondary, outline, ghost, danger }

enum ButtonSize { large, medium, compact }

enum IconPosition { leading, trailing }

/// Canonical Configurable Button for UNIQUE BASKET.
class AppButton extends StatelessWidget {
  final String? label;
  final String? text; // Backwards-compatible alias for label
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final IconPosition iconPosition;
  final Widget? prefix;
  final Widget? suffix;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    this.label,
    this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.large,
    this.icon,
    this.iconPosition = IconPosition.leading,
    this.prefix,
    this.suffix,
    this.height,
    this.borderRadius,
    this.padding,
  }) : assert(label != null || text != null, 'Either label or text must be provided');

  String get _displayLabel => label ?? text ?? '';

  double _resolveHeight(BuildContext context) {
    if (height != null) return height!;
    switch (size) {
      case ButtonSize.large:
        return context.r(52.0).clamp(48.0, 56.0);
      case ButtonSize.medium:
        return context.r(44.0).clamp(40.0, 48.0);
      case ButtonSize.compact:
        return context.r(36.0).clamp(32.0, 40.0);
    }
  }

  double _resolveFontSize(BuildContext context) {
    switch (size) {
      case ButtonSize.large:
        return context.sp(15.5);
      case ButtonSize.medium:
        return context.sp(14.0);
      case ButtonSize.compact:
        return context.sp(12.5);
    }
  }

  double _resolveIconSize(BuildContext context) {
    switch (size) {
      case ButtonSize.large:
        return 20.0;
      case ButtonSize.medium:
        return 18.0;
      case ButtonSize.compact:
        return 16.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor;
    Color textColor;
    BorderSide borderSide;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = isDark ? const Color(0xFF00695C) : AppColors.primary;
        textColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.secondary:
        backgroundColor = isDark ? AppColors.surfaceContainerDark : const Color(0xFFE6F4EA);
        textColor = isDark ? const Color(0xFF34D399) : AppColors.primary;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = isDark ? const Color(0xFF34D399) : AppColors.primary;
        borderSide = BorderSide(
          color: isDark ? const Color(0xFF34D399) : AppColors.primary,
          width: 1.5,
        );
        break;
      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = isDark ? const Color(0xFF34D399) : AppColors.primary;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.danger:
        backgroundColor = AppColors.error;
        textColor = AppColors.onError;
        borderSide = BorderSide.none;
        break;
    }

    final isEnabled = onPressed != null && !isLoading;
    final resolvedBorderRadius = borderRadius ?? BorderRadius.circular(999.0);
    final resolvedHeight = _resolveHeight(context);
    final resolvedFontSize = _resolveFontSize(context);
    final resolvedIconSize = _resolveIconSize(context);

    return SizedBox(
      height: resolvedHeight,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? backgroundColor : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          foregroundColor: isEnabled ? textColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
          disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          disabledForegroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: resolvedBorderRadius,
            side: isEnabled ? borderSide : BorderSide.none,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        child: isLoading
            ? SizedBox(
                height: resolvedIconSize,
                width: resolvedIconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefix != null) ...[
                    prefix!,
                    const SizedBox(width: 8.0),
                  ] else if (icon != null && iconPosition == IconPosition.leading) ...[
                    Icon(icon, size: resolvedIconSize, color: isEnabled ? textColor : const Color(0xFF94A3B8)),
                    const SizedBox(width: 8.0),
                  ],
                  Flexible(
                    child: Text(
                      _displayLabel,
                      style: TextStyle(
                        fontSize: resolvedFontSize,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTextStyles.fontFamily,
                        color: isEnabled ? textColor : const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (suffix != null) ...[
                    const SizedBox(width: 8.0),
                    suffix!,
                  ] else if (icon != null && iconPosition == IconPosition.trailing) ...[
                    const SizedBox(width: 8.0),
                    Icon(icon, size: resolvedIconSize, color: isEnabled ? textColor : const Color(0xFF94A3B8)),
                  ],
                ],
              ),
      ),
    );
  }
}
