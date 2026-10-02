import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/order_details_provider.dart';
import '../widgets/order_bill_summary_card.dart';
import '../widgets/order_item_card.dart';

/// Screen 22 — Order Details matching 22_Order_Details.png.
class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final String? orderNumber;
  final Map<String, dynamic>? initialOrderData;

  const OrderDetailsScreen({
    super.key,
    this.orderId,
    this.orderNumber,
    this.initialOrderData,
  });

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  void _handleBack(BuildContext context) {
    HapticFeedback.lightImpact();
    if (context.canPop()) {
      context.pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedOrderId = widget.orderId ??
        widget.initialOrderData?['order']?['id'] as String? ??
        widget.initialOrderData?['id'] as String? ??
        '';

    if (resolvedOrderId.isEmpty && widget.initialOrderData == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppHeader(
          title: 'Order Details',
          showBackButton: true,
          centerTitle: true,
          onBackTap: () => _handleBack(context),
          backgroundColor: const Color(0xFF014D40),
          foregroundColor: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22.0),
            bottomRight: Radius.circular(22.0),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64.0,
                    color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'No Order Selected',
                    style: TextStyle(
                      fontSize: context.sp(18.0),
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Please select an order to view its itemized breakdown.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.sp(13.5),
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                  ),
                  AppButton(
                    label: 'Go Back',
                    variant: ButtonVariant.primary,
                    size: ButtonSize.medium,
                    borderRadius: BorderRadius.circular(12.0),
                    isFullWidth: false,
                    onPressed: () => _handleBack(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // If orderId is available, watch the provider
    final orderAsync = resolvedOrderId.isNotEmpty
        ? ref.watch(orderDetailsProvider(resolvedOrderId))
        : null;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppHeader(
          title: 'Order Details',
          showBackButton: true,
          centerTitle: true,
          onBackTap: () => _handleBack(context),
          backgroundColor: const Color(0xFF014D40),
          foregroundColor: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22.0),
            bottomRight: Radius.circular(22.0),
          ),
        ),
        body: SafeArea(
          child: orderAsync != null
              ? orderAsync.when(
                  data: (data) => _buildContent(context, data, isDark),
                  loading: () => widget.initialOrderData != null
                      ? _buildContent(context, widget.initialOrderData!, isDark)
                      : _buildLoadingState(isDark),
                  error: (error, _) => widget.initialOrderData != null
                      ? _buildContent(context, widget.initialOrderData!, isDark)
                      : _buildErrorState(context, resolvedOrderId, isDark),
                )
              : _buildContent(context, widget.initialOrderData!, isDark),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> rawOrderData,
    bool isDark,
  ) {
    final order = rawOrderData['order'] as Map<String, dynamic>? ?? rawOrderData;

    final String rawOrderNumber = order['orderNumber'] as String? ??
        order['order_number'] as String? ??
        widget.orderNumber ??
        '';

    final String displayOrderNumber = rawOrderNumber.startsWith('#')
        ? rawOrderNumber
        : (rawOrderNumber.isNotEmpty ? '#$rawOrderNumber' : '#UB-ORDER');

    final dynamic createdAtRaw = order['createdAt'] ?? order['created_at'];
    final String formattedDate = _formatOrderDate(createdAtRaw);

    final List<dynamic> itemsList = order['items'] is List
        ? order['items'] as List<dynamic>
        : (widget.initialOrderData?['items'] is List
            ? widget.initialOrderData!['items'] as List<dynamic>
            : const []);

    final int itemCount = (order['itemCount'] as num?)?.toInt() ??
        itemsList.length;

    final double subtotal = _parseDouble(order['subtotal'] ?? 0);
    final double deliveryFee = _parseDouble(order['deliveryFee'] ?? order['delivery_fee'] ?? 0);
    final double codCharge = _parseDouble(order['codCharge'] ?? order['cod_charge'] ?? 0);
    final double discount = _parseDouble(order['discount'] ?? 0);
    final double grandTotal = _parseDouble(order['total'] ?? order['grandTotal'] ?? (subtotal + deliveryFee + codCharge - discount));

    final String? paymentMethod = order['paymentMethod'] as String? ??
        order['payment_method'] as String? ??
        widget.initialOrderData?['paymentMethod'] as String?;

    final Map<String, dynamic>? address = order['address'] as Map<String, dynamic>? ??
        widget.initialOrderData?['address'] as Map<String, dynamic>?;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Order Meta Header Row (#UB-DDMMYY-XXX and Date/Time)
              _buildMetaHeader(
                context: context,
                orderNumber: displayOrderNumber,
                formattedDate: formattedDate,
                itemCount: itemCount,
                isDark: isDark,
              ),
              const SizedBox(height: 16.0),

              // 2. Order Items List
              if (itemsList.isNotEmpty) ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: itemsList.length,
                  itemBuilder: (context, index) {
                    final itemMap = itemsList[index] as Map<String, dynamic>;
                    return OrderItemCard(item: itemMap);
                  },
                ),
                const SizedBox(height: 4.0),
              ],

              // 3. Financial Bill Summary Card
              OrderBillSummaryCard(
                subtotal: subtotal > 0 ? subtotal : (grandTotal - deliveryFee - codCharge + discount),
                deliveryFee: deliveryFee,
                codCharge: codCharge,
                discount: discount,
                grandTotal: grandTotal,
                paymentMethod: paymentMethod,
                address: address,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaHeader({
    required BuildContext context,
    required String orderNumber,
    required String formattedDate,
    required int itemCount,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Order ID (Full format, no unnecessary truncation)
            Flexible(
              child: Text(
                orderNumber,
                style: TextStyle(
                  fontSize: context.sp(20.0),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF014D40),
                  fontFamily: AppTextStyles.fontFamily,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (formattedDate.isNotEmpty) ...[
              const SizedBox(width: 8.0),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: context.sp(12.5),
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF64748B),
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4.0),

        // Item count subtitle
        Text(
          itemCount == 1 ? '1 item' : '$itemCount items',
          style: TextStyle(
            fontSize: context.sp(13.5),
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : const Color(0xFF64748B),
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF014D40)),
            strokeWidth: 3.0,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Loading order details...',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String orderId, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56.0,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Failed to Load Order Details',
              style: TextStyle(
                fontSize: context.sp(18.0),
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'We were unable to retrieve the breakdown for this order. Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.sp(13.5),
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
            AppButton(
              label: 'Retry',
              variant: ButtonVariant.primary,
              size: ButtonSize.medium,
              borderRadius: BorderRadius.circular(12.0),
              isFullWidth: false,
              icon: Icons.refresh_rounded,
              iconPosition: IconPosition.leading,
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(orderDetailsProvider(orderId));
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatOrderDate(dynamic rawDate) {
    if (rawDate == null) return '';
    try {
      DateTime dt;
      if (rawDate is DateTime) {
        dt = rawDate;
      } else if (rawDate is String) {
        dt = DateTime.parse(rawDate).toLocal();
      } else {
        return '';
      }
      return DateFormat('dd MMM yyyy • h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
