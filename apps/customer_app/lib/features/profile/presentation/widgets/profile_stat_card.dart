import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';

class ProfileStatItem {
  final String label;
  final int count;
  final VoidCallback? onTap;

  const ProfileStatItem({
    required this.label,
    required this.count,
    this.onTap,
  });
}

class ProfileStatRow extends StatelessWidget {
  final List<ProfileStatItem> stats;

  const ProfileStatRow({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: context.h(AppSpacing.xs),
      ),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: _buildStatCard(context, stats[i], isDark),
            ),
          ],

        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    ProfileStatItem item,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark
              ? AppColors.surfaceContainerDark
              : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: item.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: context.h(14.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: context.sp(11.0),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.textMutedDark
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  '${item.count}',
                  style: TextStyle(
                    fontSize: context.sp(20.0),
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF014D40),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
