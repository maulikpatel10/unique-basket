import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Text query suggestion item with arrow icon matching Screen 17 (17_Search.png).
class SearchQuerySuggestionItem extends StatelessWidget {
  final String query;
  final VoidCallback onTap;

  const SearchQuerySuggestionItem({
    super.key,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20.0,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textMuted,
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Text(
                query,
                style: TextStyle(
                  fontSize: context.sp(14.5),
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontFamily: AppTextStyles.fontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.north_west_rounded,
              size: 18.0,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

