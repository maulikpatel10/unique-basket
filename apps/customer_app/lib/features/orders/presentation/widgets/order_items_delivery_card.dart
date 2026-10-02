import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Screen 21 Order Items & Delivery Address Card matching 21_Order_Tracking.png.
class OrderItemsDeliveryCard extends StatelessWidget {
  final int itemCount;
  final double totalAmount;
  final Map<String, dynamic>? address;
  final VoidCallback? onViewItemsTap;

  const OrderItemsDeliveryCard({
    super.key,
    required this.itemCount,
    required this.totalAmount,
    this.address,
    this.onViewItemsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final addressType = address?['type'] ?? address?['title'] ?? 'Home';
    final receiverName = address?['receiverName'] ?? address?['name'] ?? 'Maulik Patel';
    final addressLine = address?['addressLine'] ?? address?['address'] ?? '123 Green Heights, Opp Central Park';
    final city = address?['city'] ?? 'Ahmedabad';

    final fullAddressString = '$receiverName, $addressLine, $city';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Order Items Summary Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Icon Container
              Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 20.0,
                    color: Color(0xFF014D40),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),

              // Title & Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Items ($itemCount ${itemCount == 1 ? 'item' : 'items'})',
                      style: TextStyle(
                        fontSize: context.sp(14.5),
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),

              // Right: Total Price & View items Link
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(totalAmount),
                    style: TextStyle(
                      fontSize: context.sp(16.0),
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  InkWell(
                    key: const Key('order_tracking_view_items_button'),
                    onTap: onViewItemsTap,
                    borderRadius: BorderRadius.circular(4.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View items',
                            style: TextStyle(
                              fontSize: context.sp(12.0),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF014D40),
                              fontFamily: AppTextStyles.fontFamily,
                            ),
                          ),
                          const SizedBox(width: 2.0),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16.0,
                            color: Color(0xFF014D40),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Divider(
              height: 1.0,
              color: isDark
                  ? AppColors.cardBorderDark.withValues(alpha: 0.6)
                  : const Color(0xFFF1F5F9),
            ),
          ),

          // 2. Delivery Address Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 20.0,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Delivering to $addressType: ',
                        style: TextStyle(
                          fontSize: context.sp(13.0),
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                      ),
                      TextSpan(
                        text: fullAddressString,
                        style: TextStyle(
                          fontSize: context.sp(13.0),
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          fontFamily: AppTextStyles.fontFamily,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
