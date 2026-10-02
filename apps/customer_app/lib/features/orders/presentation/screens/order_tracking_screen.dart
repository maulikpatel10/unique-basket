import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/order_tracking_provider.dart';
import '../widgets/order_items_delivery_card.dart';
import '../widgets/order_progress_timeline.dart';
import '../widgets/tracking_hero_banner.dart';
import 'order_details_screen.dart';

/// Screen 21 — Order Tracking Screen matching 21_Order_Tracking.png.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final String? orderNumber;
  final Map<String, dynamic>? initialOrderData;

  const OrderTrackingScreen({
    super.key,
    this.orderId,
    this.orderNumber,
    this.initialOrderData,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  void _handleBack(BuildContext context) {
    HapticFeedback.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        GoRouter.of(context).go(RouteNames.home);
      } catch (_) {
        // Fallback
      }
    }
  }

  void _handleContactSupport(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support: Please call +91 98765 43210 or email support@uniquebasket.com'),
        duration: Duration(seconds: 3),
        backgroundColor: Color(0xFF014D40),
      ),
    );
  }

  void _handleViewItems(
    BuildContext context, {
    required String orderId,
    required String orderNumber,
    required dynamic items,
    Map<String, dynamic>? orderData,
  }) {
    HapticFeedback.lightImpact();
    try {
      context.push(
        RouteNames.orderDetails,
        extra: {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'items': items,
          if (orderData != null) 'order': orderData,
        },
      );
    } catch (_) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrderDetailsScreen(
            orderId: orderId,
            orderNumber: orderNumber,
            initialOrderData: {
              'orderId': orderId,
              'orderNumber': orderNumber,
              'items': items,
              if (orderData != null) 'order': orderData,
            },
          ),
        ),
      );
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

    // If orderId is completely missing and no initial order data is provided
    if (resolvedOrderId.isEmpty && widget.initialOrderData == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
        appBar: AppHeader(
          title: 'Track Order',
          showBackButton: true,
          onBackTap: () => _handleBack(context),
          centerTitle: false,
          backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
          foregroundColor: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22.0),
            bottomRight: Radius.circular(22.0),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 64.0, color: Color(0xFF94A3B8)),
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
                  'Unable to locate order tracking information.',
                  style: TextStyle(
                    fontSize: context.sp(14.0),
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppButton(
                  label: 'Back to Home',
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
      );
    }

    // Fetch live tracking data via Riverpod provider if orderId exists
    final trackingAsync = resolvedOrderId.isNotEmpty
        ? ref.watch(orderTrackingProvider(resolvedOrderId))
        : null;

    // Use initial data as fallback while loading or on error
    final order = trackingAsync?.asData?.value ??
        widget.initialOrderData?['order'] as Map<String, dynamic>? ??
        widget.initialOrderData;

    // Handle initial loading without fallback data
    if (order == null && trackingAsync != null && trackingAsync.isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
        appBar: AppHeader(
          title: 'Track Order',
          showBackButton: true,
          onBackTap: () => _handleBack(context),
          centerTitle: false,
          backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
          foregroundColor: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22.0),
            bottomRight: Radius.circular(22.0),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF014D40),
          ),
        ),
      );
    }

    // Handle error without fallback data
    if (order == null && trackingAsync != null && trackingAsync.hasError) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
        appBar: AppHeader(
          title: 'Track Order',
          showBackButton: true,
          onBackTap: () => _handleBack(context),
          centerTitle: false,
          backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
          foregroundColor: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22.0),
            bottomRight: Radius.circular(22.0),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64.0, color: Color(0xFFDC2626)),
                const SizedBox(height: 16.0),
                Text(
                  'Failed to Load Tracking',
                  style: TextStyle(
                    fontSize: context.sp(18.0),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Please check your internet connection and try again.',
                  style: TextStyle(
                    fontSize: context.sp(14.0),
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppButton(
                  label: 'Retry',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.medium,
                  borderRadius: BorderRadius.circular(12.0),
                  isFullWidth: false,
                  icon: Icons.refresh_rounded,
                  iconPosition: IconPosition.leading,
                  onPressed: () => ref.invalidate(orderTrackingProvider(resolvedOrderId)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Resolve order attributes
    final String resolvedOrderNumber = order?['orderNumber'] as String? ??
        widget.orderNumber ??
        (resolvedOrderId.isNotEmpty
            ? 'UB-${resolvedOrderId.substring(0, resolvedOrderId.length > 8 ? 8 : resolvedOrderId.length).toUpperCase()}'
            : 'UB-${DateTime.now().millisecondsSinceEpoch}');

    final String rawStatus = order?['orderStatus'] as String? ??
        order?['status'] as String? ??
        'PREPARING';

    final itemsList = (order?['items'] as List<dynamic>?) ?? const [];
    final helper = OrderTrackingStatusHelper(
      rawStatus: rawStatus,
      itemsList: itemsList,
    );

    final double resolvedTotal = _parseDouble(order?['total'] ?? order?['grandTotal'] ?? order?['totalAmount']);
    final int resolvedItemCount = (order?['itemCount'] as num?)?.toInt() ??
        (itemsList.isNotEmpty ? itemsList.length : 1);

    final address = order?['address'] as Map<String, dynamic>?;
    final createdAt = order?['createdAt'] as String?;
    final destinationCity = address?['city'] as String? ?? 'Ahmedabad';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
      appBar: AppHeader(
        title: 'Track Order',
        showBackButton: true,
        onBackTap: () => _handleBack(context),
        centerTitle: false,
        backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
        foregroundColor: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22.0),
          bottomRight: Radius.circular(22.0),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF014D40),
          onRefresh: () async {
            if (resolvedOrderId.isNotEmpty) {
              ref.invalidate(orderTrackingProvider(resolvedOrderId));
              try {
                await ref.read(orderTrackingProvider(resolvedOrderId).future);
              } catch (_) {
                // Handled by Riverpod async value
              }
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Sub-Header Meta Row: ORDER ID & LIVE ORDER Pill
                    _buildMetaRow(
                      context: context,
                      orderNumber: resolvedOrderNumber,
                      helper: helper,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16.0),

                    // 2. Current Status Hero Banner
                    TrackingHeroBanner(helper: helper),
                    const SizedBox(height: 18.0),

                    // 3. 5-Stage Order Progress Timeline
                    OrderProgressTimeline(
                      helper: helper,
                      createdAt: createdAt,
                      destinationCity: destinationCity,
                    ),
                    const SizedBox(height: 18.0),

                    // 4. Order Items & Delivery Address Card
                    OrderItemsDeliveryCard(
                      itemCount: resolvedItemCount,
                      totalAmount: resolvedTotal,
                      address: address,
                      onViewItemsTap: () => _handleViewItems(
                        context,
                        orderId: resolvedOrderId,
                        orderNumber: resolvedOrderNumber,
                        items: itemsList,
                        orderData: order ?? widget.initialOrderData,
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // 5. Help & Support Footer CTA
                    _buildSupportFooter(context, isDark),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow({
    required BuildContext context,
    required String orderNumber,
    required OrderTrackingStatusHelper helper,
    required bool isDark,
  }) {
    final formattedNumber = orderNumber.startsWith('#') ? orderNumber : '#$orderNumber';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: ORDER ID Label + Capsule
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ORDER ID',
                style: TextStyle(
                  fontSize: context.sp(11.0),
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
              const SizedBox(width: 6.0),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    formattedNumber,
                    style: TextStyle(
                      fontSize: context.sp(12.0),
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6.0),

        // Right: Status Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: helper.isCancelled
                ? const Color(0xFFFEE2E2)
                : helper.isDelivered
                    ? const Color(0xFFE6F4EA)
                    : const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(999.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: helper.isCancelled
                      ? const Color(0xFFDC2626)
                      : helper.isDelivered
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5.0),
              Text(
                helper.isCancelled
                    ? 'CANCELLED'
                    : helper.isDelivered
                        ? 'DELIVERED'
                        : 'LIVE ORDER',
                style: TextStyle(
                  fontSize: context.sp(10.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: helper.isCancelled
                      ? const Color(0xFFDC2626)
                      : helper.isDelivered
                          ? const Color(0xFF014D40)
                          : const Color(0xFF014D40),
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportFooter(BuildContext context, bool isDark) {
    return Center(
      child: InkWell(
        key: const Key('order_tracking_support_button'),
        onTap: () => _handleContactSupport(context),
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.support_agent_rounded,
                size: 18.0,
                color: Color(0xFF014D40),
              ),
              const SizedBox(width: 6.0),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Need help with this order? ',
                        style: TextStyle(
                          fontSize: context.sp(13.0),
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                      ),
                      TextSpan(
                        text: 'Contact Support',
                        style: TextStyle(
                          fontSize: context.sp(13.0),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF014D40),
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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
