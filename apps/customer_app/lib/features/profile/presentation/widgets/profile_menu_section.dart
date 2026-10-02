import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';

class ProfileMenuRowItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  const ProfileMenuRowItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.titleColor,
    this.onTap,
  });
}

class ProfileMenuSection extends StatelessWidget {
  final String sectionTitle;
  final List<ProfileMenuRowItem> items;

  const ProfileMenuSection({
    super.key,
    required this.sectionTitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.h(AppSpacing.xs + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: 8.0,
            ),
            child: Text(
              sectionTitle.toUpperCase(),
              style: TextStyle(
                fontSize: context.sp(12.0),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.8,
                indent: context.w(68),
                endIndent: AppSpacing.lg,
                color: isDark
                    ? AppColors.dividerDark
                    : const Color(0xFFF1F5F9),
              ),
            _buildRow(context, items[i], isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    ProfileMenuRowItem item,
    bool isDark,
  ) {
    final defaultIconBg = isDark ? const Color(0xFF00382E) : const Color(0xFFE7F5F4);
    final defaultIconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF014D40);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: context.h(13.0),
          ),
          child: Row(
            children: [
              Container(
                width: context.w(42),
                height: context.w(42),
                decoration: BoxDecoration(
                  color: item.iconBgColor ?? defaultIconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: context.sp(20.0),
                    color: item.iconColor ?? defaultIconColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: context.sp(14.5),
                        fontWeight: FontWeight.w700,
                        color: item.titleColor ??
                            (isDark
                                ? AppColors.textPrimaryDark
                                : const Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: context.sp(12.5),
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: context.sp(22.0),
                color: item.titleColor != null
                    ? item.titleColor!.withValues(alpha: 0.8)
                    : (isDark
                        ? AppColors.textMutedDark
                        : const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
