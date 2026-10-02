import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';

class NotificationSectionHeader extends StatelessWidget {
  final String title;
  final String? dateText;

  const NotificationSectionHeader({
    super.key,
    required this.title,
    this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: context.h(AppSpacing.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: context.sp(12.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? AppColors.textTertiaryDark : const Color(0xFF64748B),
            ),
          ),
          if (dateText != null && dateText!.isNotEmpty)
            Text(
              dateText!,
              style: TextStyle(
                fontSize: context.sp(12.0),
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }
}
