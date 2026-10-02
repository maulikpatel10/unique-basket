import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Presentation card displaying the financial bill summary for Screen 22 (22_Order_Details.png).
class OrderBillSummaryCard extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double codCharge;
  final double discount;
  final double grandTotal;
  final String? paymentMethod;
  final Map<String, dynamic>? address;

  const OrderBillSummaryCard({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    this.codCharge = 0.0,
    this.discount = 0.0,
    required this.grandTotal,
    this.paymentMethod,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dividerColor = isDark
        ? AppColors.cardBorderDark.withValues(alpha: 0.6)
        : const Color(0xFFF1F5F9);

    final String addressLabel = address != null
        ? '${address!['type'] ?? 'Home'} • ${address!['receiverName'] ?? address!['name'] ?? 'Customer'}'
        : '';

    final String addressText = address != null
        ? '${address!['addressLine'] ?? address!['address'] ?? ''}${address!['landmark'] != null && address!['landmark'].toString().isNotEmpty ? ', ${address!['landmark']}' : ''}, ${address!['city'] ?? 'Rajkot'}'
        : '';

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
          // 1. Subtotal
          _buildSummaryRow(
            context: context,
            label: 'Subtotal',
            value: CurrencyFormatter.format(subtotal),
            isDark: isDark,
          ),
          const SizedBox(height: 12.0),

          // 2. Delivery Fee
          _buildSummaryRow(
            context: context,
            label: 'Delivery Fee',
            value: deliveryFee == 0
                ? 'FREE'
                : CurrencyFormatter.format(deliveryFee),
            valueColor: deliveryFee == 0
                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981))
                : null,
            isDark: isDark,
          ),

          // 3. COD Charge (if any)
          if (codCharge > 0) ...[
            const SizedBox(height: 12.0),
            _buildSummaryRow(
              context: context,
              label: 'Cash Handling Fee',
              value: CurrencyFormatter.format(codCharge),
              isDark: isDark,
            ),
          ],

          // 4. Discount (if any)
          if (discount > 0) ...[
            const SizedBox(height: 12.0),
            _buildSummaryRow(
              context: context,
              label: 'Discount',
              value: '-${CurrencyFormatter.format(discount)}',
              valueColor: isDark
                  ? const Color(0xFF34D399)
                  : const Color(0xFF10B981),
              isDark: isDark,
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: dividerColor, height: 1.0, thickness: 1.0),
          ),

          // 5. Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: context.sp(18.0),
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
              Text(
                CurrencyFormatter.format(grandTotal),
                style: TextStyle(
                  fontSize: context.sp(22.0),
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF014D40),
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ],
          ),

          // 6. Optional Payment & Delivery Address Footer
          if ((paymentMethod != null && paymentMethod!.isNotEmpty) ||
              addressText.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(color: dividerColor, height: 1.0, thickness: 1.0),
            ),
            if (paymentMethod != null && paymentMethod!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      paymentMethod!.toUpperCase() == 'COD'
                          ? Icons.money_rounded
                          : Icons.account_balance_wallet_outlined,
                      size: 16.0,
                      color: const Color(0xFF014D40),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Paid via ${paymentMethod!.toUpperCase() == 'COD' ? 'Cash on Delivery' : paymentMethod!}',
                        style: TextStyle(
                          fontSize: context.sp(12.5),
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF475569),
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (addressText.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16.0,
                    color: Color(0xFF014D40),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      addressLabel.isNotEmpty
                          ? '$addressLabel — $addressText'
                          : addressText,
                      style: TextStyle(
                        fontSize: context.sp(12.0),
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF64748B),
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required BuildContext context,
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.sp(14.0),
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : const Color(0xFF64748B),
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.sp(14.5),
            fontWeight: FontWeight.w700,
            color: valueColor ??
                (isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A)),
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
      ],
    );
  }
}
