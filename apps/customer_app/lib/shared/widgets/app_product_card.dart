import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
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
        borderRadius: BorderRadius.circular(16.0),
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
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
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
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Stack(
                    children: [
                      // Centered visual icon / network image (dimmed when out of stock)
                      Opacity(
                        opacity: isPurchasable ? 1.0 : 0.45,
                        child: Center(
                          child: imageUrl != null && imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
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
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 5.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF014D40),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                fontFamily: AppTextStyles.fontFamily,
                              ),
                            ),
                          ),
                        ),

                      // Top-Left Badge (e.g. "16% OFF" or "Local") - shown only when purchasable
                      if (isPurchasable && badge != null && badge!.isNotEmpty)
                        Positioned(
                          top: 8.0,
                          left: 8.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: badge == 'Local'
                                  ? const Color(0xFF854D0E)
                                  : const Color(0xFF9E4B00),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),

                      // Top-Right Favorite Button (Hit-tested independently)
                      Positioned(
                        top: 0.0,
                        right: 0.0,
                        child: _CardFavoriteButton(
                          isFavorite: isFavorite,
                          onToggle: onToggleFavorite,
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

class _CardFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onToggle;

  const _CardFavoriteButton({
    required this.isFavorite,
    this.onToggle,
  });

  @override
  State<_CardFavoriteButton> createState() => _CardFavoriteButtonState();
}

class _CardFavoriteButtonState extends State<_CardFavoriteButton> {
  bool _isTapped = false;

  void _handleTap() {
    setState(() => _isTapped = true);
    widget.onToggle?.call();
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _isTapped = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40.0,
        height: 40.0,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: AnimatedScale(
          scale: _isTapped ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: Container(
            width: 28.0,
            height: 28.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                widget.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 15.0,
                color: widget.isFavorite
                    ? const Color(0xFF014D40)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
