import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../home/data/models/category_model.dart';
import '../providers/search_provider.dart';

/// Filter, Sort & Category selector bar matching Screen 18 (18_Search_Results.png).
class SearchFilterBar extends StatelessWidget {
  final int totalCount;
  final String query;
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final SearchSortOption sortOption;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<SearchSortOption> onSortSelected;
  final VoidCallback onFilterTap;

  const SearchFilterBar({
    super.key,
    required this.totalCount,
    required this.query,
    required this.categories,
    required this.selectedCategoryId,
    required this.sortOption,
    required this.onCategorySelected,
    required this.onSortSelected,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Meta Results Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: context.sp(13.5),
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                fontFamily: AppTextStyles.fontFamily,
              ),
              children: [
                const TextSpan(text: 'Showing '),
                TextSpan(
                  text: '$totalCount ${totalCount == 1 ? 'product' : 'products'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF014D40),
                  ),
                ),
                if (query.isNotEmpty) ...[
                  const TextSpan(text: ' for "'),
                  TextSpan(
                    text: query,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    ),
                  ),
                  const TextSpan(text: '"'),
                ],
              ],
            ),
          ),
        ),

        // 2. Filter, Sort and Category Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              // Filter Pill Button
              _buildPillButton(
                context: context,
                isDark: isDark,
                isSelected: selectedCategoryId != null,
                icon: Icons.tune_rounded,
                label: selectedCategoryId != null ? 'Filter •' : 'Filter',
                onTap: onFilterTap,
              ),
              const SizedBox(width: 8.0),

              // Sort Dropdown / Popup Pill Button
              PopupMenuButton<SearchSortOption>(
                initialValue: sortOption,
                onSelected: onSortSelected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                color: isDark ? AppColors.surfaceDark : Colors.white,
                itemBuilder: (context) => SearchSortOption.values.map((option) {
                  return PopupMenuItem<SearchSortOption>(
                    value: option,
                    child: Row(
                      children: [
                        Icon(
                          option == sortOption
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 18.0,
                          color: option == sortOption
                              ? const Color(0xFF014D40)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: option == sortOption
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : const Color(0xFF0F172A),
                            fontFamily: AppTextStyles.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark
                          ? AppColors.cardBorderDark
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sort: ${sortOption.label}',
                        style: TextStyle(
                          fontSize: context.sp(12.5),
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16.0,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // Category Filter Pills
              _buildCategoryChip(
                context: context,
                isDark: isDark,
                label: 'All',
                isSelected: selectedCategoryId == null,
                onTap: () => onCategorySelected(null),
              ),
              ...categories.map((cat) {
                final isSelected = selectedCategoryId == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _buildCategoryChip(
                    context: context,
                    isDark: isDark,
                    label: cat.name,
                    isSelected: isSelected,
                    onTap: () => onCategorySelected(isSelected ? null : cat.id),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillButton({
    required BuildContext context,
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF014D40)
              : (isDark ? AppColors.surfaceContainerDark : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF014D40)
                : (isDark ? AppColors.cardBorderDark : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15.0,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A)),
            ),
            const SizedBox(width: 5.0),
            Text(
              label,
              style: TextStyle(
                fontSize: context.sp(12.5),
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A)),
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required bool isDark,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF014D40)
              : (isDark ? AppColors.surfaceContainerDark : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF014D40)
                : (isDark ? AppColors.cardBorderDark : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.sp(12.5),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textPrimaryDark : const Color(0xFF334155)),
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
      ),
    );
  }
}
