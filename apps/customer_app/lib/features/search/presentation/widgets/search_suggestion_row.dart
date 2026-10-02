import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../home/data/models/product_model.dart';

/// Product suggestion row matching Screen 17 (17_Search.png), acting purely as a
/// search selection row to assist users in completing their search.
class SearchSuggestionRow extends StatelessWidget {
  final ProductModel product;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchSuggestionRow({
    super.key,
    required this.product,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rLg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Thumbnail Image matching Cart/Checkout styling
            Container(
              width: context.r(54.0),
              height: context.r(54.0),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : const Color(0xFFF1F5F9),
                borderRadius: AppRadius.rMd,
                border: Border.all(
                  color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
                  width: 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11.0),
                child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackThumbnail(isDark),
                      )
                    : _buildFallbackThumbnail(isDark),
              ),
            ),
            const SizedBox(width: 12.0),

            // 2. Product Name, Price, Unit & Badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHighlightedTitle(context, isDark),
                  const SizedBox(height: 3.0),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6.0,
                    runSpacing: 2.0,
                    children: [
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: TextStyle(
                          fontSize: context.sp(14.0),
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : AppColors.primary,
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                      ),
                      if (product.unit.isNotEmpty)
                        Text(
                          '• ${product.unit}',
                          style: TextStyle(
                            fontSize: context.sp(12.0),
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                            fontFamily: AppTextStyles.fontFamily,
                          ),
                        ),
                      if (!product.isPurchasable)
                        _buildBadge('Out of Stock', AppColors.error, isDark)
                      else if (product.resolvedBadge != null)
                        _buildBadge(product.resolvedBadge!, AppColors.tertiary, isDark),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8.0),

            // 3. Trailing Search Suggestion Indicator (↖)
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

  Widget _buildFallbackThumbnail(bool isDark) {
    return Center(
      child: Icon(
        Icons.eco_rounded,
        size: 26.0,
        color: isDark ? AppColors.textSecondaryDark : AppColors.primary,
      ),
    );
  }

  Widget _buildBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: AppTextStyles.fontFamily,
        ),
      ),
    );
  }

  Widget _buildHighlightedTitle(BuildContext context, bool isDark) {
    final title = product.name;
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty || !title.toLowerCase().contains(query)) {
      return Text(
        title,
        style: TextStyle(
          fontSize: context.sp(14.5),
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          fontFamily: AppTextStyles.fontFamily,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final startIndex = title.toLowerCase().indexOf(query);
    final endIndex = startIndex + query.length;

    final before = title.substring(0, startIndex);
    final matched = title.substring(startIndex, endIndex);
    final after = title.substring(endIndex);

    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: context.sp(14.5),
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          fontFamily: AppTextStyles.fontFamily,
        ),
        children: [
          if (before.isNotEmpty)
            TextSpan(
              text: before,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          TextSpan(
            text: matched,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF34D399) : AppColors.primary,
            ),
          ),
          if (after.isNotEmpty)
            TextSpan(
              text: after,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

