import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Presentation card displaying an individual order item for Screen 22 (22_Order_Details.png).
class OrderItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const OrderItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String productName = item['productName'] as String? ??
        item['product']?['name'] as String? ??
        'Product Item';

    final String unit = item['unit'] as String? ??
        item['product']?['unit'] as String? ??
        '';

    final String? imageUrl = item['imageUrl'] as String? ??
        item['product']?['imageUrl'] as String?;

    final double quantity = _parseDouble(item['quantity'] ?? 1);
    final double unitPrice = _parseDouble(item['unitPrice'] ?? item['price'] ?? 0);
    final double totalPrice = _parseDouble(item['totalPrice'] ?? (quantity * unitPrice));

    final String formattedQty = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Product Image Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              width: context.w(64.0),
              height: context.w(64.0),
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImagePlaceholder(isDark),
                    )
                  : _buildImagePlaceholder(isDark),
            ),
          ),
          const SizedBox(width: 14.0),

          // 2. Product Name, Unit & Price Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Title
                Text(
                  productName,
                  style: TextStyle(
                    fontSize: context.sp(15.0),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3.0),

                // Unit & Quantity Description
                Row(
                  children: [
                    if (unit.isNotEmpty)
                      Flexible(
                        child: Text(
                          unit,
                          style: TextStyle(
                            fontSize: context.sp(12.5),
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF64748B),
                            fontFamily: AppTextStyles.fontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (unit.isNotEmpty && quantity > 1)
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: context.sp(12.0),
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    if (quantity > 1)
                      Text(
                        'Qty: $formattedQty',
                        style: TextStyle(
                          fontSize: context.sp(12.0),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF014D40),
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6.0),

                // Price display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(totalPrice),
                      style: TextStyle(
                        fontSize: context.sp(15.5),
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF014D40),
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                    ),
                    if (quantity > 1 && unitPrice > 0)
                      Text(
                        '($formattedQty × ${CurrencyFormatter.format(unitPrice)})',
                        style: TextStyle(
                          fontSize: context.sp(11.5),
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF94A3B8),
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 26.0,
        color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
      ),
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
