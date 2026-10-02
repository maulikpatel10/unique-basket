import 'package:flutter/material.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/category_item.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/models/category_model.dart';

/// Screen 08 (Home) Explore Categories section.
///
/// Composes the reusable [SectionHeader] and horizontal list of [CategoryItem]s.
class HomeCategoriesSection extends StatelessWidget {
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel>? onCategoryTap;
  final VoidCallback? onViewAllTap;

  const HomeCategoriesSection({
    super.key,
    required this.categories,
    this.onCategoryTap,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row: "Explore Categories" & "View all"
        SectionHeader(
          title: 'Explore Categories',
          actionText: 'View all',
          onActionTap: onViewAllTap,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Horizontal Category Circles
        SizedBox(
          height: context.r(112),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14.0),
            itemBuilder: (context, index) {
              final category = categories[index];
              const categoryColors = [
                Color(0xFFEA580C), // Warm Orange / Red
                Color(0xFF16A34A), // Fresh Green
                Color(0xFF0284C7), // Sky Blue
              ];
              final itemColor = categoryColors[index % categoryColors.length];
              return CategoryItem(
                id: category.id,
                name: category.name,
                imageUrl: category.imageUrl,
                color: itemColor,
                onTap: () => onCategoryTap?.call(category),
              );
            },
          ),
        ),
      ],
    );
  }
}
