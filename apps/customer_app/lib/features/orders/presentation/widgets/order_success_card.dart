import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Presentation card displaying confirmed order details for Screen 20 (20_Order_Success.png).
class OrderSuccessCard extends StatelessWidget {
  final String orderNumber;
  final double totalPaid;
  final int itemCount;
  final String paymentMethod;
  final String? paymentDetail;
  final String? addressLabel;
  final String? addressText;

  const OrderSuccessCard({
    super.key,
    required this.orderNumber,
    required this.totalPaid,
    required this.itemCount,
    required this.paymentMethod,
    this.paymentDetail,
    this.addressLabel,
    this.addressText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formattedNumber = orderNumber.startsWith('#') ? orderNumber : '#$orderNumber';
    final isOnline = paymentMethod.toUpperCase() == 'ONLINE' ||
        paymentMethod.toUpperCase() == 'UPI';

    final dividerColor = isDark
        ? AppColors.cardBorderDark.withValues(alpha: 0.6)
        : const Color(0xFFF1F5F9);

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
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Order ID & Total Paid Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Order ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORDER ID',
                      style: TextStyle(
                        fontSize: context.sp(11.0),
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      formattedNumber,
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
              const SizedBox(width: 12.0),

              // Right: Total Paid
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL PAID',
                    style: TextStyle(
                      fontSize: context.sp(11.0),
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    CurrencyFormatter.format(totalPaid),
                    style: TextStyle(
                      fontSize: context.sp(19.0),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF014D40),
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Divider(height: 1.0, color: dividerColor),
          ),

          // 2. Items Count Row
          Row(
            children: [
              Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF014D40).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 16.0,
                    color: Color(0xFF014D40),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Text(
                '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  fontSize: context.sp(14.0),
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10.0),

          // 3. Payment Method Row
          Row(
            children: [
              Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16.0,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: isOnline
                    ? Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Paid via UPI ',
                              style: TextStyle(
                                fontSize: context.sp(13.5),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF014D40),
                                fontFamily: AppTextStyles.fontFamily,
                              ),
                            ),
                            if (paymentDetail != null && paymentDetail!.isNotEmpty)
                              TextSpan(
                                text: '($paymentDetail)',
                                style: TextStyle(
                                  fontSize: context.sp(12.5),
                                  fontWeight: FontWeight.w400,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : const Color(0xFF64748B),
                                  fontFamily: AppTextStyles.fontFamily,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        'Cash on Delivery',
                        style: TextStyle(
                          fontSize: context.sp(13.5),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF014D40),
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                      ),
              ),
            ],
          ),

          if (addressText != null && addressText!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(height: 1.0, color: dividerColor),
            ),

            // 4. Delivery Address Row
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (addressLabel != null && addressLabel!.isNotEmpty)
                        Text(
                          addressLabel!,
                          style: TextStyle(
                            fontSize: context.sp(13.5),
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                            fontFamily: AppTextStyles.fontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2.0),
                      Text(
                        addressText!,
                        style: TextStyle(
                          fontSize: context.sp(12.5),
                          fontWeight: FontWeight.w400,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          fontFamily: AppTextStyles.fontFamily,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
