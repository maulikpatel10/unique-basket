import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import 'app_badge.dart';
import 'app_icon_button.dart';
import 'product_quantity_control.dart';

/// Presentation-only reusable Product Card for Unique Basket.
///
/// Invariants:
/// - Exact deterministic layout with zero vertical or horizontal shift on quantity adjustments.
/// - Top image container (112dp) with badge and isolated favorite button.
/// - Title (18dp) with ellipsis.
/// - Pack info / unit (16dp).
/// - Price row (32dp) with anchored price on left and morphing [ProductQuantityControl] or Out-of-Stock pill on right.
class AppProductCard extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final String unit;
  final double? oldPrice;
  final String? badge;
  final String? imageUrl;
  final IconData? visualIcon;
  final Color? visualColor;
  final int quantity;
  final bool isFavorite;
  final bool isPurchasable;
  final VoidCallback? onAddToCart;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTap;

  const AppProductCard({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    this.oldPrice,
    this.badge,
    this.imageUrl,
    this.visualIcon,
    this.visualColor,
    this.quantity = 0,
    this.isFavorite = false,
    this.isPurchasable = true,
    this.onAddToCart,
    this.onIncrement,
    this.onDecrement,
    this.onToggleFavorite,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedVisualColor = visualColor ?? _getDefaultVisualColor(name);
    final resolvedVisualIcon = visualIcon ?? _getDefaultVisualIcon(name);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.rLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rLg,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Image Container with badge and favorite button
                Container(
                  height: context.r(112),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : const Color(0xFFF1F5F9),
                    borderRadius: AppRadius.rMd,
                  ),
                  child: Stack(
                    children: [
                      // Centered visual icon / network image (dimmed when out of stock)
                      Opacity(
                        opacity: isPurchasable ? 1.0 : 0.45,
                        child: Center(
                          child: imageUrl != null && imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: AppRadius.rSm,
                                  child: Image.network(
                                    imageUrl!,
                                    width: context.r(80),
                                    height: context.r(80),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: context.r(60),
                                      height: context.r(60),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: resolvedVisualColor
                                            .withValues(alpha: 0.15),
                                      ),
                                      child: Icon(
                                        resolvedVisualIcon,
                                        size: context.r(36),
                                        color: resolvedVisualColor,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: context.r(60),
                                  height: context.r(60),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: resolvedVisualColor
                                        .withValues(alpha: 0.15),
                                  ),
                                  child: Icon(
                                    resolvedVisualIcon,
                                    size: context.r(36),
                                    color: resolvedVisualColor,
                                  ),
                                ),
                        ),
                      ),

                      // Centered "OUT OF STOCK" pill badge over image
                      if (!isPurchasable)
                        const Center(
                          child: AppBadge(
                            text: 'OUT OF STOCK',
                            variant: BadgeVariant.stock,
                          ),
                        ),

                      // Top-Left Badge (e.g. "16% OFF" or "Local") - shown only when purchasable
                      if (isPurchasable && badge != null && badge!.isNotEmpty)
                        Positioned(
                          top: 8.0,
                          left: 8.0,
                          child: AppBadge(
                            text: badge!,
                            variant: BadgeVariant.discount,
                          ),
                        ),

                      // Top-Right Favorite Button (Hit-tested independently)
                      Positioned(
                        top: 0.0,
                        right: 0.0,
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          alignment: Alignment.center,
                          child: AppIconButton(
                            icon: isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            variant: IconButtonVariant.surface,
                            size: 28.0,
                            iconSize: 15.0,
                            color: isFavorite
                                ? const Color(0xFF014D40)
                                : const Color(0xFF94A3B8),
                            animateTap: true,
                            onPressed: onToggleFavorite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8.0),

                // Product Title (Fixed deterministic height)
                SizedBox(
                  height: 18.0,
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: context.sp(13.5),
                      fontWeight: FontWeight.w700,
                      color: !isPurchasable
                          ? (isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B))
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A)),
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 2.0),

                // Unit / Pack Size (Fixed deterministic height)
                SizedBox(
                  height: 16.0,
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: context.sp(11.5),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 8.0),

                // Bottom Row: Price & Action (Fixed deterministic height 32.0)
                SizedBox(
                  height: 32.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price
                      Expanded(
                        child: Text(
                          CurrencyFormatter.format(price),
                          style: TextStyle(
                            fontSize: context.sp(15.5),
                            fontWeight: FontWeight.w800,
                            color: !isPurchasable
                                ? (isDark ? AppColors.textMutedDark : const Color(0xFF739B93))
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : const Color(0xFF014D40)),
                            fontFamily: AppTextStyles.fontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4.0),

                      // Morphing Action Control OR Out-of-Stock state (32.0 height parity)
                      if (isPurchasable)
                        ProductQuantityControl(
                          quantity: quantity,
                          isDark: isDark,
                          onAddToCart: onAddToCart,
                          onIncrement: onIncrement,
                          onDecrement: onDecrement,
                        )
                      else
                        Container(
                          width: 32.0,
                          height: 32.0,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFF7BA19A),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add_rounded,
                              size: 20.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _getDefaultVisualColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('avocado')) return const Color(0xFF15803D);
    if (lower.contains('tomato')) return const Color(0xFFDC2626);
    if (lower.contains('banana')) return const Color(0xFFCA8A04);
    if (lower.contains('spinach')) return const Color(0xFF047857);
    if (lower.contains('apple')) return const Color(0xFFB91C1C);
    if (lower.contains('berry') || lower.contains('strawberry')) {
      return const Color(0xFFBE185D);
    }
    if (lower.contains('mango') || lower.contains('orange')) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFF014D40);
  }

  static IconData _getDefaultVisualIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('avocado')) return Icons.eco_rounded;
    if (lower.contains('tomato')) return Icons.circle_rounded;
    if (lower.contains('banana') || lower.contains('fruit')) {
      return Icons.energy_savings_leaf_rounded;
    }
    if (lower.contains('spinach') || lower.contains('greens')) {
      return Icons.spa_rounded;
    }
    return Icons.eco_rounded;
  }
}

