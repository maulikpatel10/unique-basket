import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../address/presentation/providers/customer_address_provider.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../payment/data/models/saved_payment_method_model.dart';
import '../../../payment/presentation/providers/payment_methods_provider.dart';
import '../../../profile_setup/presentation/providers/customer_profile_provider.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../providers/order_provider.dart';

/// Screen 16 — Checkout for Unique Basket Customer App.
///
/// Implements the approved 16_Checkout design specification:
/// - Dark pine green header (#014D40) with rounded bottom corners and back navigation.
/// - YOUR CART section with dynamic item count, thumbnails, title, pack, price,
///   and canonical [ProductQuantityControl].
/// - DELIVERY ADDRESS section with default address card, location icon, and Change action.
/// - PAYMENT METHOD section with UPI and Pay On Delivery interactive radio options.
/// - BILL DETAILS section with itemized subtotal, delivery fee, special bag discount,
///   handling, dynamic To Pay calculation, savings badge, and full-width "PLACE ORDER 🔒" CTA.
/// - Empty cart safety returning smoothly to cart when basket is cleared.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  static const double _specialBagDiscount = 20.0;
  bool _isSubmitting = false;
  bool _orderPlaced = false;

  void _handleBack() {
    HapticFeedback.lightImpact();
    if (context.mounted) {
      if (Navigator.of(context).canPop()) {
        context.pop();
      } else {
        try {
          context.go(RouteNames.cart);
        } catch (_) {
          // Fallback
        }
      }
    }
  }

  void _handleChangeAddress() {
    HapticFeedback.lightImpact();
    try {
      context.push(RouteNames.myAddresses);
    } catch (_) {
      // Fallback
    }
  }

  void _handleChangePayment() {
    HapticFeedback.lightImpact();
    try {
      context.push(RouteNames.paymentMethods);
    } catch (_) {
      // Fallback
    }
  }

  Future<void> _handlePlaceOrder({
    required List<Map<String, dynamic>> items,
    required String? addressId,
    required String? storeId,
    required CheckoutPaymentMethod paymentMethod,
    required double toPay,
    int? itemCount,
    Map<String, dynamic>? address,
  }) async {
    if (_isSubmitting || _orderPlaced) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final backendPaymentMethod =
          paymentMethod == CheckoutPaymentMethod.upi ? 'ONLINE' : 'COD';

      final response = await orderRepo.createOrder(
        fulfillmentType: 'DELIVERY',
        addressId: addressId,
        storeId: storeId,
        paymentMethod: backendPaymentMethod,
        items: items,
      );

      final Map<String, dynamic>? orderData = (response['order'] ??
              response['data']?['order'] ??
              response['data'] ??
              response) as Map<String, dynamic>?;
      final orderNumber = orderData?['orderNumber'] as String? ??
          orderData?['order_number'] as String? ??
          '';

      _orderPlaced = true;

      if (!mounted) return;

      // Resolve backend-authoritative total from server response
      final backendOrderTotal = orderData != null && orderData['total'] != null
          ? (orderData['total'] is num
              ? (orderData['total'] as num).toDouble()
              : double.tryParse(orderData['total'].toString()) ?? toPay)
          : toPay;

      // Navigate to Screen 20 (Order Success)
      try {
        GoRouter.of(context).go(
          RouteNames.orderSuccess,
          extra: {
            'order': orderData,
            'orderNumber': orderNumber,
            'totalAmount': backendOrderTotal,
            'itemCount': itemCount ?? items.length,
            'paymentMethod': backendPaymentMethod,
            'paymentDetail': backendPaymentMethod == 'ONLINE' ? 'UPI' : 'Cash on Delivery',
            'address': address,
          },
        );
      } catch (_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }

      // Clear the user's cart upon confirmed order placement
      ref.read(cartNotifierProvider.notifier).clearCart();
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Failed to place order. Please try again.';
      final errorStr = e.toString();

      if (errorStr.contains('INSUFFICIENT_STOCK')) {
        errorMessage = 'Some items in your cart are no longer available in the requested quantity.';
      } else if (errorStr.contains('NO_DELIVERY_AVAILABLE')) {
        errorMessage = 'Delivery is currently not available for this address location.';
      } else if (errorStr.contains('MINIMUM_DELIVERY_AMOUNT_NOT_MET')) {
        errorMessage = 'Order amount does not meet the minimum delivery requirement.';
      } else if (errorStr.contains('COD_DISABLED')) {
        errorMessage = 'Cash on Delivery is currently disabled. Please select UPI.';
      } else if (errorStr.contains('UNAUTHORIZED') || errorStr.contains('401')) {
        errorMessage = 'Please sign in to complete your order.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted && !_orderPlaced) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cart = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final int totalCount = cartNotifier.totalItemCount;

    // Safety: If cart is empty while on Checkout, return to cart/home (unless order placed or submitting)
    if (totalCount == 0 || cart.isEmpty) {
      if (!_isSubmitting && !_orderPlaced) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isSubmitting && !_orderPlaced) {
            try {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.cart);
              }
            } catch (_) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            }
          }
        });
      }
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
        appBar: AppHeader(
          title: 'Checkout',
          showBackButton: true,
          onBackTap: _handleBack,
          centerTitle: true,
          backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
          foregroundColor: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22.0),
            bottomRight: Radius.circular(22.0),
          ),
        ),
        body: const SizedBox.shrink(),
      );
    }

    // Retrieve store products to populate details
    final productsAsync = ref.watch(homeProductsProvider);
    final List<ProductModel> storeProducts = productsAsync.asData?.value ?? const [];

    // Resolve cart items
    final List<_CheckoutCartItem> cartItems = [];
    final List<Map<String, dynamic>> orderPayloadItems = [];
    double subtotal = 0.0;

    for (final entry in cart.entries) {
      final productId = entry.key;
      final quantity = entry.value;
      if (quantity <= 0) continue;

      final matchedProduct = storeProducts.cast<ProductModel?>().firstWhere(
            (p) => p?.id == productId,
            orElse: () => null,
          );

      final product = matchedProduct ??
          ProductModel(
            id: productId,
            categoryId: 'cat_general',
            name: 'Fresh Item',
            price: 0.0,
            unit: '1 unit',
            stockQuantity: 10.0,
          );

      final itemTotal = product.price * quantity;
      subtotal += itemTotal;

      cartItems.add(_CheckoutCartItem(
        product: product,
        quantity: quantity,
        itemTotal: itemTotal,
      ));

      orderPayloadItems.add({
        'productId': productId,
        'quantity': quantity,
      });
    }

    // Resolve Delivery Address
    final defaultAddressAsync = ref.watch(defaultCustomerAddressProvider);
    final defaultAddress = defaultAddressAsync.asData?.value;

    // Resolve Customer Profile for Name and Phone
    final profileAsync = ref.watch(customerProfileProvider);
    final profile = profileAsync.asData?.value;

    final customerName = profile?['name'] as String? ?? 'Maulik Patel';
    final customerPhone = profile?['phone'] as String? ??
        (defaultAddress?['phone'] as String? ?? '+91 98765 43210');

    final addressTitle = defaultAddress?['title'] as String? ?? 'Home';
    final addressLine = defaultAddress?['addressLine'] as String? ??
        '123, Example Road, Green Heights, Opp. Central Park, Ahmedabad, Gujarat 380001';
    final addressId = defaultAddress?['id'] as String?;

    // Resolve Serving Store
    final servingStoreAsync = ref.watch(servingStoreProvider);
    final servingStore = servingStoreAsync.asData?.value;
    final storeId = servingStore?.id;

    // Payment Method selection
    final selectedPayment = ref.watch(selectedPaymentMethodProvider);
    final savedPaymentMethods = ref.watch(paymentMethodsProvider).valueOrNull ?? [];
    final defaultUpi = savedPaymentMethods.cast<SavedPaymentMethod?>().firstWhere(
          (m) => m?.type == PaymentMethodType.upi && m?.isDefault == true,
          orElse: () => savedPaymentMethods.cast<SavedPaymentMethod?>().firstWhere(
            (m) => m?.type == PaymentMethodType.upi,
            orElse: () => null,
          ),
        );
    final upiTitle = defaultUpi != null && defaultUpi.subtitle.isNotEmpty
        ? 'UPI — ${defaultUpi.subtitle}'
        : (defaultUpi?.title ?? 'UPI — maulik@okaxis');

    // Authoritative Cart & Pricing summary from backend
    final cartSummaryAsync = ref.watch(cartSummaryProvider);
    final cartSummary = cartSummaryAsync.asData?.value;

    // Delivery settings from backend
    final deliverySettingsAsync = ref.watch(deliverySettingsProvider);
    final deliverySettings = deliverySettingsAsync.asData?.value;
    final double backendDeliveryFeeConfig = deliverySettings?.deliveryFee ?? 30.0;
    final double freeDeliveryThreshold = cartSummary?.freeDeliveryThreshold ??
        (deliverySettings?.freeDeliveryThreshold ?? 499.0);

    // Authoritative pricing values derived from backend source of truth
    final double authoritativeSubtotal = (cartSummary != null && cartSummary.subtotal > 0)
        ? cartSummary.subtotal
        : subtotal;

    final double deliveryFee = (cartSummary != null && cartSummary.subtotal > 0)
        ? cartSummary.deliveryFee
        : (authoritativeSubtotal > 0
            ? (authoritativeSubtotal >= freeDeliveryThreshold ? 0.0 : backendDeliveryFeeConfig)
            : 0.0);

    final double discount = (cartSummary != null && cartSummary.discount > 0)
        ? cartSummary.discount
        : (authoritativeSubtotal >= _specialBagDiscount ? _specialBagDiscount : 0.0);

    // Final authoritative payable amount from backend pricing
    final double toPay = (cartSummary != null && cartSummary.total > 0)
        ? (cartSummary.total - (cartSummary.discount > 0 ? 0.0 : discount)).clamp(0.0, double.infinity)
        : (authoritativeSubtotal + deliveryFee - discount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
      appBar: AppHeader(
        title: 'Checkout',
        showBackButton: true,
        onBackTap: _handleBack,
        centerTitle: false,
        backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
        foregroundColor: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22.0),
          bottomRight: Radius.circular(22.0),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. YOUR CART SECTION CARD
              _buildSectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Row(
                      children: [
                        Text(
                          'YOUR CART',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          '($totalCount ${totalCount == 1 ? 'item' : 'items'})',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // Cart Items List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartItems.length,
                      separatorBuilder: (_, __) => Divider(
                        color: isDark ? AppColors.cardBorderDark : const Color(0xFFF1F5F9),
                        height: 24.0,
                        thickness: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final product = item.product;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Product Image Thumbnail
                            Container(
                              width: context.r(58),
                              height: context.r(58),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                color: isDark
                                    ? AppColors.surfaceContainerDark
                                    : const Color(0xFFF1F5F9),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.cardBorderDark
                                      : const Color(0xFFE2E8F0),
                                  width: 1.0,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11.0),
                                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        product.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.eco_rounded,
                                          color: const Color(0xFF014D40),
                                          size: context.r(26),
                                        ),
                                      )
                                    : Icon(
                                        Icons.eco_rounded,
                                        color: const Color(0xFF014D40),
                                        size: context.r(26),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12.0),

                            // Product Title, Unit & Price
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: context.sp(14),
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    product.unit,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: context.sp(12),
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    '₹${product.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: context.sp(14),
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF014D40),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8.0),

                            // Product Quantity Control
                            ProductQuantityControl(
                              quantity: item.quantity,
                              isDark: isDark,
                              onIncrement: () => ref
                                  .read(cartNotifierProvider.notifier)
                                  .increment(product.id),
                              onDecrement: () => ref
                                  .read(cartNotifierProvider.notifier)
                                  .decrement(product.id),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14.0),

              // 2. DELIVERY ADDRESS SECTION CARD
              _buildSectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with Change
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'DELIVERY ADDRESS',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: context.sp(14),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _handleChangeAddress,
                          borderRadius: BorderRadius.circular(6.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            child: Text(
                              'Change',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: context.sp(13),
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF014D40),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),

                    // Address Info Box
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceContainerDark.withValues(alpha: 0.5)
                            : const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(
                          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14.0),
                        child: InkWell(
                          onTap: _handleChangeAddress,
                          borderRadius: BorderRadius.circular(14.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Home Icon Badge
                                Container(
                                  width: context.r(36),
                                  height: context.r(36),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? const Color(0xFF014D40).withValues(alpha: 0.35)
                                        : const Color(0xFFE7F5F4),
                                  ),
                                  child: Icon(
                                    Icons.home_rounded,
                                    size: context.r(20),
                                    color: isDark
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF014D40),
                                  ),
                                ),
                                const SizedBox(width: 10.0),

                                // Address Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title and Default Indicator
                                      Row(
                                        children: [
                                          Text(
                                            addressTitle,
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              fontSize: context.sp(14),
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? AppColors.textPrimaryDark
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(width: 8.0),
                                          Container(
                                            width: 6.0,
                                            height: 6.0,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF16A34A),
                                            ),
                                          ),
                                          const SizedBox(width: 6.0),
                                          Text(
                                            'Default',
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              fontSize: context.sp(12),
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF16A34A),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3.0),

                                      // Customer Name
                                      Text(
                                        customerName,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: context.sp(13),
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3.0),

                                      // Address Line
                                      Text(
                                        addressLine,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: context.sp(12),
                                          fontWeight: FontWeight.w400,
                                          height: 1.35,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                      const SizedBox(height: 6.0),

                                      // Phone Row
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone_outlined,
                                            size: context.r(13),
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 5.0),
                                          Text(
                                            customerPhone,
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              fontSize: context.sp(12),
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14.0),

              // 3. PAYMENT METHOD SECTION CARD
              _buildSectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with Change
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'PAYMENT METHOD',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: context.sp(14),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _handleChangePayment,
                          borderRadius: BorderRadius.circular(6.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            child: Text(
                              'Change',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: context.sp(13),
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF014D40),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),

                    // Option 1: UPI
                    _buildPaymentOptionTile(
                      isDark: isDark,
                      isSelected: selectedPayment == CheckoutPaymentMethod.upi,
                      title: upiTitle,
                      subtitle: 'Instant payment via UPI app',
                      icon: Icons.account_balance_wallet_rounded,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(selectedPaymentMethodProvider.notifier)
                            .state = CheckoutPaymentMethod.upi;
                      },
                    ),

                    const SizedBox(height: 10.0),

                    // Option 2: Pay On Delivery
                    _buildPaymentOptionTile(
                      isDark: isDark,
                      isSelected: selectedPayment == CheckoutPaymentMethod.cod,
                      title: 'Pay On Delivery',
                      subtitle: 'Pay cash at time of delivery',
                      icon: Icons.payments_rounded,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(selectedPaymentMethodProvider.notifier)
                            .state = CheckoutPaymentMethod.cod;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14.0),

              // 4. BILL DETAILS SECTION CARD
              _buildSectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BILL DETAILS',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Items Subtotal
                    _buildBillRow(
                      isDark: isDark,
                      label: 'Items Subtotal',
                      value: '₹${subtotal.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 10.0),

                    // Delivery Fee
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Delivery Fee',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: context.sp(13),
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        deliveryFee == 0.0
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${backendDeliveryFeeConfig.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: context.sp(13),
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.lineThrough,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    'FREE',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: context.sp(13),
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                '₹${deliveryFee.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: context.sp(13),
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    // Special Bag Discount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🏷 ', style: TextStyle(fontSize: 13)),
                              Flexible(
                                child: Text(
                                  'Special Bag Discount',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: context.sp(13),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '-₹${discount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: context.sp(13),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    // Handling & Taxes
                    _buildBillRow(
                      isDark: isDark,
                      label: 'Handling & Taxes',
                      value: 'FREE',
                      valueColor: const Color(0xFF16A34A),
                      valueFontWeight: FontWeight.w800,
                    ),

                    const SizedBox(height: 14.0),
                    Divider(
                      color: isDark ? AppColors.cardBorderDark : const Color(0xFFF1F5F9),
                      height: 1.0,
                      thickness: 1.0,
                    ),
                    const SizedBox(height: 14.0),

                    // To Pay Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'To Pay',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '₹${toPay.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: context.sp(18),
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF014D40),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14.0),

                    // Savings Pill Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF014D40).withValues(alpha: 0.25)
                            : const Color(0xFFE7F5F4),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF014D40).withValues(alpha: 0.45)
                              : const Color(0xFFCDECE9),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '🎉 You saved ₹${discount.toStringAsFixed(2)} on this order',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: context.sp(13),
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF014D40),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18.0),

                    // PLACE ORDER CTA BUTTON
                    AppButton(
                      label: 'PLACE ORDER',
                      variant: ButtonVariant.primary,
                      size: ButtonSize.large,
                      isLoading: _isSubmitting,
                      icon: Icons.lock_outline_rounded,
                      iconPosition: IconPosition.trailing,
                      onPressed: _isSubmitting
                          ? null
                          : () => _handlePlaceOrder(
                                items: orderPayloadItems,
                                addressId: addressId,
                                storeId: storeId,
                                paymentMethod: selectedPayment,
                                toPay: toPay,
                                itemCount: cartItems.fold<int>(
                                    0, (sum, i) => sum + i.quantity),
                                address: {
                                  'type': addressTitle,
                                  'receiverName': customerName,
                                  'addressLine': addressLine,
                                  'phone': customerPhone,
                                },
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.rXl,
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14.0),
      child: child,
    );
  }

  Widget _buildPaymentOptionTile({
    required bool isDark,
    required bool isSelected,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF014D40))
        : (isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0));

    final bgColor = isSelected
        ? (isDark
            ? const Color(0xFF014D40).withValues(alpha: 0.25)
            : const Color(0xFFE7F5F4).withValues(alpha: 0.6))
        : (isDark ? AppColors.surfaceContainerDark.withValues(alpha: 0.4) : Colors.white);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: const Color(0xFF014D40),
              ),
              child: Icon(
                icon,
                size: 20.0,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12.0),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5.0),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 15.0,
                        color: Color(0xFF16A34A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10.0),

            // Radio Circle
            Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF014D40))
                      : const Color(0xFF94A3B8),
                  width: isSelected ? 5.5 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow({
    required bool isDark,
    required String label,
    required String value,
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13.0,
            fontWeight: valueFontWeight ?? FontWeight.w700,
            color: valueColor ??
                (isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}

class _CheckoutCartItem {
  final ProductModel product;
  final int quantity;
  final double itemTotal;

  _CheckoutCartItem({
    required this.product,
    required this.quantity,
    required this.itemTotal,
  });
}
