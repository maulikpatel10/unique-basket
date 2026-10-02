import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/order_success_card.dart';

/// Screen 20 — Order Success matching 20_Order_Success.png.
class OrderSuccessScreen extends ConsumerWidget {
  final Map<String, dynamic>? orderData;
  final String? orderId;

  const OrderSuccessScreen({
    super.key,
    this.orderData,
    this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Extract real order parameters from passed data
    final order = orderData?['order'] as Map<String, dynamic>? ?? orderData ?? {};
    final String? resolvedOrderId = order['id'] as String? ?? orderId;
    final String resolvedOrderNumber = order['orderNumber'] as String? ??
        orderData?['orderNumber'] as String? ??
        order['order_number'] as String? ??
        orderData?['order_number'] as String? ??
        (resolvedOrderId != null && resolvedOrderId.isNotEmpty
            ? 'UB-${resolvedOrderId.substring(0, resolvedOrderId.length > 8 ? 8 : resolvedOrderId.length).toUpperCase()}'
            : 'UB-ORDER');

    final double resolvedTotal = _parseDouble(order['total'] ?? order['grandTotal'] ?? order['totalAmount'] ?? orderData?['totalAmount']);
    final int resolvedItemCount = (order['itemCount'] as num?)?.toInt() ??
        (orderData?['itemCount'] as num?)?.toInt() ??
        (order['items'] is List ? (order['items'] as List).length : 1);

    final String paymentMethod = (order['paymentMethod'] as String? ??
            orderData?['paymentMethod'] as String? ??
            'ONLINE')
        .toUpperCase();

    final String? paymentDetail = orderData?['paymentDetail'] as String? ??
        (paymentMethod == 'ONLINE' || paymentMethod == 'UPI' ? 'UPI' : null);

    final address = orderData?['address'] as Map<String, dynamic>? ??
        order['address'] as Map<String, dynamic>?;

    final String addressLabel = address != null
        ? '${address['type'] ?? 'Home'} • ${address['receiverName'] ?? address['name'] ?? 'Customer'}'
        : 'Home • Delivery Address';

    final String addressText = address != null
        ? '${address['addressLine'] ?? address['address'] ?? ''}${address['landmark'] != null && address['landmark'].toString().isNotEmpty ? ', ${address['landmark']}' : ''}, ${address['city'] ?? 'Rajkot'}'
        : 'Delivering to your registered location';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _navigateToHome(context);
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: const AppHeader(
          title: 'UNIQUE BASKET',
          showBackButton: false,
          centerTitle: true,
          backgroundColor: Color(0xFF014D40),
          foregroundColor: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(22.0),
            bottomRight: Radius.circular(22.0),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Success Checkmark Graphic Container
                    _buildSuccessIllustration(context, isDark),
                    SizedBox(height: context.h(20.0)),

                    // 2. Headline & Subtitle
                    Text(
                      'Order Placed Successfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.sp(22.0),
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Your order is confirmed. We\'re getting your fresh groceries ready.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.sp(14.0),
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          fontFamily: AppTextStyles.fontFamily,
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(24.0)),

                    // 3. Order Summary Card
                    OrderSuccessCard(
                      orderNumber: resolvedOrderNumber,
                      totalPaid: resolvedTotal,
                      itemCount: resolvedItemCount,
                      paymentMethod: paymentMethod,
                      paymentDetail: paymentDetail,
                      addressLabel: addressLabel,
                      addressText: addressText,
                    ),
                    SizedBox(height: context.h(28.0)),

                    // 4. Primary CTA: Track Order
                    AppButton(
                      key: const Key('order_success_track_button'),
                      label: 'Track Order',
                      variant: ButtonVariant.primary,
                      size: ButtonSize.large,
                      icon: Icons.local_shipping_outlined,
                      iconPosition: IconPosition.leading,
                      onPressed: () => _handleTrackOrder(
                        context,
                        resolvedOrderNumber,
                        resolvedOrderId,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // 5. Secondary CTA: Continue Shopping
                    InkWell(
                      key: const Key('order_success_continue_shopping'),
                      onTap: () => _navigateToHome(context),
                      borderRadius: BorderRadius.circular(8.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Continue Shopping',
                              style: TextStyle(
                                fontSize: context.sp(14.5),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF014D40),
                                fontFamily: AppTextStyles.fontFamily,
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16.0,
                              color: Color(0xFF014D40),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIllustration(BuildContext context, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow circle
        Container(
          width: context.r(110.0),
          height: context.r(110.0),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7).withValues(alpha: 0.75),
            shape: BoxShape.circle,
          ),
        ),

        // Decorative Wheat / Star Accents
        Positioned(
          top: 6,
          right: 12,
          child: Icon(
            Icons.auto_awesome,
            size: 16.0,
            color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 10,
          child: Icon(
            Icons.eco_rounded,
            size: 16.0,
            color: const Color(0xFF10B981).withValues(alpha: 0.9),
          ),
        ),

        // Inner solid green check circle
        Container(
          width: context.r(72.0),
          height: context.r(72.0),
          decoration: const BoxDecoration(
            color: Color(0xFF014D40),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x24014D40),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              size: 40.0,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToHome(BuildContext context) {
    try {
      GoRouter.of(context).go(RouteNames.home);
    } catch (_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleTrackOrder(BuildContext context, String orderNumber, String? resolvedOrderId) {
    try {
      GoRouter.of(context).push(
        RouteNames.orderTracking,
        extra: {
          'orderNumber': orderNumber,
          'orderId': resolvedOrderId,
          'order': orderData?['order'] ?? orderData,
        },
      );
    } catch (_) {
      // Fallback
    }
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
