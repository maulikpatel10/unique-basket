import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../screens/order_details_screen.dart';
import '../screens/order_tracking_screen.dart';

/// Presentation card displaying an order summary on Screen 27 (27_My_Orders.png).
class OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderHistoryCard({
    super.key,
    required this.order,
  });

  bool get _isActiveOrder {
    final status = (order['orderStatus'] as String? ?? 'PLACED').toUpperCase();
    return status == 'PLACED' ||
        status == 'CONFIRMED' ||
        status == 'PREPARING' ||
        status == 'READY_FOR_PICKUP' ||
        status == 'PICKED_UP' ||
        status == 'OUT_FOR_DELIVERY';
  }

  void _handleAction(BuildContext context) {
    HapticFeedback.lightImpact();
    final orderId = (order['id'] as String? ?? '').trim();
    final rawNumber = (order['orderNumber'] as String? ?? '').trim();
    final orderNumber = rawNumber.isNotEmpty
        ? (rawNumber.startsWith('#') ? rawNumber : '#$rawNumber')
        : '#UB-ORDER';

    final extraData = {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'order': order,
      if (order['items'] != null) 'items': order['items'],
    };

    if (_isActiveOrder) {
      try {
        context.push(RouteNames.orderTracking, extra: extraData);
      } catch (_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => OrderTrackingScreen(
              orderId: orderId,
              orderNumber: orderNumber,
              initialOrderData: extraData,
            ),
          ),
        );
      }
    } else {
      try {
        context.push(RouteNames.orderDetails, extra: extraData);
      } catch (_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => OrderDetailsScreen(
              orderId: orderId,
              orderNumber: orderNumber,
              initialOrderData: extraData,
            ),
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';
    try {
      final parsed = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final orderDate = DateTime(parsed.year, parsed.month, parsed.day);

      final timeFormatter = DateFormat('h:mm a');
      final timeStr = timeFormatter.format(parsed);

      if (orderDate == today) {
        return 'Today • $timeStr';
      } else if (orderDate == yesterday) {
        return 'Yesterday • $timeStr';
      } else {
        final dateFormatter = DateFormat('dd MMM yyyy');
        return '${dateFormatter.format(parsed)} • $timeStr';
      }
    } catch (_) {
      return dateStr;
    }
  }

  String _buildItemSummary(dynamic itemsRaw) {
    if (itemsRaw is! List || itemsRaw.isEmpty) {
      return '1 item';
    }

    final totalCount = itemsRaw.length;
    final itemNames = <String>[];

    for (final item in itemsRaw) {
      if (item is Map<String, dynamic>) {
        final name = (item['productName'] as String?)?.trim() ??
            (item['product']?['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          itemNames.add(name);
        }
      }
    }

    if (itemNames.isEmpty) {
      return '$totalCount ${totalCount == 1 ? 'item' : 'items'}';
    }

    final countPrefix = '$totalCount ${totalCount == 1 ? 'item' : 'items'}';

    if (itemNames.length == 1) {
      return '$countPrefix • ${itemNames[0]}';
    } else if (itemNames.length <= 3) {
      return '$countPrefix • ${itemNames.join(', ')}';
    } else {
      final firstThree = itemNames.take(3).join(', ');
      final remaining = itemNames.length - 3;
      return '$countPrefix • $firstThree + $remaining more';
    }
  }

  ({String label, Color textColor, Color bgColor, Color dotColor}) _getStatusBadgeInfo(
      String rawStatus, bool isDark) {
    switch (rawStatus.toUpperCase()) {
      case 'PLACED':
        return (
          label: 'Placed',
          textColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
          bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
          dotColor: const Color(0xFF3B82F6),
        );
      case 'CONFIRMED':
        return (
          label: 'Confirmed',
          textColor: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
          bgColor: isDark ? const Color(0xFF134E4A).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
          dotColor: const Color(0xFF14B8A6),
        );
      case 'PREPARING':
        return (
          label: 'Preparing',
          textColor: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
          bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5),
          dotColor: const Color(0xFF10B981),
        );
      case 'READY_FOR_PICKUP':
        return (
          label: 'Ready for Pickup',
          textColor: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
          bgColor: isDark ? const Color(0xFF451A03).withValues(alpha: 0.4) : const Color(0xFFFFFBEB),
          dotColor: const Color(0xFFF59E0B),
        );
      case 'PICKED_UP':
        return (
          label: 'On The Way',
          textColor: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
          bgColor: isDark ? const Color(0xFF451A03).withValues(alpha: 0.4) : const Color(0xFFFFFBEB),
          dotColor: const Color(0xFFF59E0B),
        );
      case 'OUT_FOR_DELIVERY':
        return (
          label: 'Out for Delivery',
          textColor: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
          bgColor: isDark ? const Color(0xFF451A03).withValues(alpha: 0.4) : const Color(0xFFFFFBEB),
          dotColor: const Color(0xFFF59E0B),
        );
      case 'DELIVERED':
        return (
          label: 'Delivered',
          textColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
          bgColor: isDark ? const Color(0xFF14532D).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
          dotColor: const Color(0xFF16A34A),
        );
      case 'CANCELLED':
        return (
          label: 'Cancelled',
          textColor: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
          bgColor: isDark ? const Color(0xFF450A0A).withValues(alpha: 0.4) : const Color(0xFFFEF2F2),
          dotColor: const Color(0xFFEF4444),
        );
      default:
        return (
          label: rawStatus,
          textColor: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          bgColor: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
          dotColor: const Color(0xFF94A3B8),
        );
    }
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rawNumber = (order['orderNumber'] as String? ?? '').trim();
    final displayOrderNumber = rawNumber.isNotEmpty
        ? (rawNumber.startsWith('#') ? rawNumber : '#$rawNumber')
        : '#UB-ORDER';

    final createdAt = order['createdAt'] as String?;
    final formattedDate = _formatDate(createdAt);

    final rawStatus = order['orderStatus'] as String? ?? 'PLACED';
    final badgeInfo = _getStatusBadgeInfo(rawStatus, isDark);

    final total = _parseDouble(order['total'] ?? order['subtotal'] ?? 0.0);
    final formattedTotal = CurrencyFormatter.format(total);

    final itemsSummary = _buildItemSummary(order['items']);
    final isActive = _isActiveOrder;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFF014D40).withValues(alpha: 0.85),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => _handleAction(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Row: Order Number (Left) & Date (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        displayOrderNumber,
                        style: TextStyle(
                          fontSize: context.sp(15.0),
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.primaryUltraLight
                              : const Color(0xFF014D40),
                          fontFamily: AppTextStyles.fontFamily,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (formattedDate.isNotEmpty) ...[
                      const SizedBox(width: 6.0),
                      Flexible(
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: context.sp(11.5),
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF64748B),
                            fontFamily: AppTextStyles.fontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10.0),

                // 2. Second Row: Status Pill Badge (Left) & Total Amount (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: badgeInfo.bgColor,
                          borderRadius: BorderRadius.circular(999.0),
                          border: Border.all(
                            color: badgeInfo.dotColor.withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.0,
                              height: 6.0,
                              decoration: BoxDecoration(
                                color: badgeInfo.dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Flexible(
                              child: Text(
                                badgeInfo.label,
                                style: TextStyle(
                                  fontSize: context.sp(12.0),
                                  fontWeight: FontWeight.w700,
                                  color: badgeInfo.textColor,
                                  fontFamily: AppTextStyles.fontFamily,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      formattedTotal,
                      style: TextStyle(
                        fontSize: context.sp(16.5),
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF0F172A),
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),

                // 3. Third Row: Items Summary Preview
                Text(
                  itemsSummary,
                  style: TextStyle(
                    fontSize: context.sp(13.0),
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF64748B),
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12.0),

                // 4. Horizontal Divider
                Divider(
                  height: 1.0,
                  thickness: 1.0,
                  color: isDark ? AppColors.cardBorderDark : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 10.0),

                // 5. Bottom Row: Action CTA
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isActive ? 'Track Order' : 'View Details',
                        style: TextStyle(
                          fontSize: context.sp(13.5),
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.primaryUltraLight
                              : const Color(0xFF014D40),
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Icon(
                        isActive
                            ? Icons.arrow_forward_rounded
                            : Icons.chevron_right_rounded,
                        size: 18.0,
                        color: isDark
                            ? AppColors.primaryUltraLight
                            : const Color(0xFF014D40),
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
}
