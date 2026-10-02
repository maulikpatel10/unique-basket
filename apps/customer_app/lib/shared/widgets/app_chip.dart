import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';

enum ChipVariant { action, input, filter }

/// Canonical Configurable Chip / Pill component for UNIQUE BASKET.
class AppChip extends StatelessWidget {
  final String label;
  final ChipVariant variant;
  final IconData? icon;
  final Widget? avatar;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final IconData deleteIcon;
  final Color? activeColor;
  final bool? isDark;

  const AppChip({
    super.key,
    required this.label,
    this.variant = ChipVariant.action,
    this.icon,
    this.avatar,
    this.isSelected = false,
    this.onTap,
    this.onDeleted,
    this.deleteIcon = Icons.close_rounded,
    this.activeColor,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkMode = isDark ?? (theme.brightness == Brightness.dark);
    final primaryColor = activeColor ?? (darkMode ? const Color(0xFF34D399) : AppColors.primary);

    final Widget? resolvedAvatar = avatar ??
        (icon != null
            ? Icon(
                icon,
                size: 16.0,
                color: isSelected
                    ? Colors.white
                    : (darkMode ? AppColors.textSecondaryDark : AppColors.textMuted),
              )
            : null);

    switch (variant) {
      case ChipVariant.input:
        return InputChip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: resolvedAvatar,
          label: Text(
            label,
            style: TextStyle(
              fontSize: context.sp(13.0),
              color: darkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
          backgroundColor: darkMode ? AppColors.surfaceContainerDark : const Color(0xFFF1F5F9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: darkMode ? AppColors.cardBorderDark : AppColors.cardBorder,
            ),
          ),
          onPressed: onTap,
          onDeleted: onDeleted,
          deleteIcon: Icon(deleteIcon, size: 14.0),
          deleteIconColor: darkMode ? AppColors.textSecondaryDark : AppColors.textMuted,
        );

      case ChipVariant.filter:
        return FilterChip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: resolvedAvatar,
          showCheckmark: false,
          label: Text(
            label,
            style: TextStyle(
              fontSize: context.sp(13.0),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (darkMode ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
          selected: isSelected,
          backgroundColor: darkMode ? AppColors.surfaceContainerDark : Colors.white,
          selectedColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: isSelected
                  ? primaryColor
                  : (darkMode ? AppColors.cardBorderDark : const Color(0xFFCBD5E1)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          onSelected: onTap != null ? (_) => onTap!() : null,
        );

      case ChipVariant.action:
        return ActionChip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: resolvedAvatar,
          label: Text(
            label,
            style: TextStyle(
              fontSize: context.sp(13.0),
              fontWeight: FontWeight.w500,
              color: primaryColor,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
          backgroundColor: darkMode
              ? AppColors.surfaceContainerDark
              : AppColors.primary.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: darkMode
                  ? AppColors.cardBorderDark
                  : AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          onPressed: onTap,
        );
    }
  }
}
