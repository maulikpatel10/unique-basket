import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';

/// Reusable atomic price display widget for UNIQUE BASKET.
///
/// Ensures all price presentation across the app adheres to the centralized
/// currency configuration (INR / ₹, Indian grouping, rounded whole numbers).
class AppPrice extends StatelessWidget {
  /// The primary selling price.
  final num price;

  /// Optional original/MRP price displayed with strikethrough.
  final num? oldPrice;

  /// Text style for the primary selling price.
  final TextStyle? priceStyle;

  /// Text style for the strikethrough MRP.
  final TextStyle? oldPriceStyle;

  /// Spacing between selling price and old price.
  final double spacing;

  /// Display layout orientation (row vs column).
  final Axis direction;

  /// Main axis alignment for the price layout.
  final MainAxisAlignment mainAxisAlignment;

  /// Cross axis alignment for the price layout.
  final CrossAxisAlignment crossAxisAlignment;

  const AppPrice({
    super.key,
    required this.price,
    this.oldPrice,
    this.priceStyle,
    this.oldPriceStyle,
    this.spacing = AppSpacing.xs,
    this.direction = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultPriceStyle = AppTextStyles.price.copyWith(
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    );
    final defaultOldPriceStyle = AppTextStyles.priceMrp.copyWith(
      color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
    );

    final formattedPrice = CurrencyFormatter.format(price);
    final priceWidget = Text(
      formattedPrice,
      style: priceStyle ?? defaultPriceStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (oldPrice == null || oldPrice! <= price) {
      return priceWidget;
    }

    final formattedOldPrice = CurrencyFormatter.format(oldPrice);
    final oldPriceWidget = Text(
      formattedOldPrice,
      style: oldPriceStyle ?? defaultOldPriceStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (direction == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          priceWidget,
          SizedBox(height: spacing),
          oldPriceWidget,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        priceWidget,
        SizedBox(width: spacing),
        oldPriceWidget,
      ],
    );
  }
}