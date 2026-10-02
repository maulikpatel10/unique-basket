import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum IconButtonVariant { surface, ghost, filled }

/// Canonical Configurable Icon Button for UNIQUE BASKET.
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final IconButtonVariant variant;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;
  final bool animateTap;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = IconButtonVariant.ghost,
    this.size = 36.0,
    this.iconSize = 20.0,
    this.color,
    this.backgroundColor,
    this.tooltip,
    this.animateTap = false,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isTapped = false;

  void _handleTap() {
    if (widget.onPressed == null) return;
    if (widget.animateTap) {
      setState(() => _isTapped = true);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _isTapped = false);
      });
    }
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null;

    Color resolvedBg;
    Color resolvedFg;
    List<BoxShadow>? shadows;
    Border? border;

    switch (widget.variant) {
      case IconButtonVariant.surface:
        resolvedBg = widget.backgroundColor ??
            (isDark ? AppColors.surfaceContainerDark : Colors.white);
        resolvedFg = widget.color ??
            (isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A));
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
        break;
      case IconButtonVariant.ghost:
        resolvedBg = widget.backgroundColor ?? Colors.transparent;
        resolvedFg = widget.color ??
            (isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A));
        break;
      case IconButtonVariant.filled:
        resolvedBg = widget.backgroundColor ??
            (isDark ? const Color(0xFF00695C) : const Color(0xFF014D40));
        resolvedFg = widget.color ?? Colors.white;
        break;
    }

    Widget button = GestureDetector(
      onTap: isEnabled ? _handleTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isTapped ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled ? resolvedBg : resolvedBg.withValues(alpha: 0.5),
            boxShadow: shadows,
            border: border,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: isEnabled ? resolvedFg : resolvedFg.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}
