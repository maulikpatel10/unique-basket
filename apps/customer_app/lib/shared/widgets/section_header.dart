import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

/// Reusable Section Header for screen sections (e.g. "Explore Categories", "Fresh Arrivals").
///
/// Features:
/// - Primary section title with responsive typography.
/// - Optional action button (e.g. "View all", "See more") with tap callback.
/// - Theme-aware light and dark styling.
/// - Consistent horizontal padding aligned to design system grid.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: context.sp(18),
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                fontFamily: AppTextStyles.fontFamily,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionText != null) ...[
            const SizedBox(width: 8.0),
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(4.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: Text(
                  actionText!,
                  style: TextStyle(
                    fontSize: context.sp(13),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF014D40),
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
