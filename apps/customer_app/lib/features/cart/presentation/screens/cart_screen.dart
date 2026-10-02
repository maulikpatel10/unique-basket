import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/providers/home_provider.dart';

/// Screen 12 — Cart (and Screen 13 — Empty Cart) for Unique Basket Customer App.
///
/// Implements the approved 12_Cart & 13_Cart_Empty design specifications:
/// - Dark green header with centered "Cart" title.
/// - Dynamic subtitle "{n} items in your basket".
/// - List of active cart items with thumbnail, title, unit, INR price, remove `✕`,
///   and shared [ProductQuantityControl].
/// - Bill Summary card with Subtotal, Delivery Fee (from backend), and Total.
/// - Full-width "Proceed to Checkout →" primary button.
/// - Automatic Screen 13 Empty State with "Start Shopping" button when cart is empty.
/// - Floating [AppBottomNavBar] with index 2 active.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  List<ProductModel>? _cachedProducts;
  CartSummaryModel? _cachedCartSummary;
  DeliverySettingsModel? _cachedDeliverySettings;

  void _handleStartShopping() {
    try {
      GoRouter.of(context).go(RouteNames.home);
    } catch (_) {
      // Fallback for standalone test harness
    }
  }

  void _handleProceedToCheckout() {
    HapticFeedback.mediumImpact();
    try {
      GoRouter.of(context).push(RouteNames.checkout);
    } catch (_) {
      // Fallback for standalone test harness without GoRouter
    }
  }

  void _handleRemoveItem(String productId, String productName) {
    HapticFeedback.lightImpact();
    ref.read(cartNotifierProvider.notifier).removeItem(productId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName removed from basket'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF014D40),
      ),
    );
  }

  void _showDeliveryFeeInfoSheet(
    BuildContext context,
    double deliveryFee,
    double freeDeliveryThreshold,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final feeText = CurrencyFormatter.format(deliveryFee);
    final thresholdText = CurrencyFormatter.format(freeDeliveryThreshold);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.0)),
      ),
      constraints: BoxConstraints(
        maxWidth: context.isTabletOrLarger ? AppBreakpoints.maxFormWidth : double.infinity,
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.sm,
              bottom: sheetCtx.h(AppSpacing.lg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40.0,
                    height: 4.0,
                    margin: const EdgeInsets.only(top: 4.0, bottom: 20.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF014D40).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_shipping_outlined,
                      size: 28.0,
                      color: Color(0xFF014D40),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Delivery Fee',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: sheetCtx.sp(18.0),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'A delivery charge of $feeText applies to this order.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: sheetCtx.sp(14.0),
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Get FREE delivery on orders above $thresholdText.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: sheetCtx.sp(13.0),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 24.0),
                AppButton(
                  label: 'Got it',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.medium,
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleRefresh() async {
    try {
      await Future.wait([
        ref.read(cartNotifierProvider.notifier).loadCart(),
        ref.refresh(cartSummaryProvider.future).catchError((_) => const CartSummaryModel()),
        ref.refresh(homeProductsProvider.future).catchError((_) => <ProductModel>[]),
        ref.refresh(deliverySettingsProvider.future).catchError((_) => const DeliverySettingsModel()),
      ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final syncStatus = ref.watch(cartSyncStatusProvider);
    final cart = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final int totalCount = cartNotifier.totalItemCount;

    // Authoritative cart summary from backend - using cache preserves previous value across AsyncLoading/refresh
    final cartSummaryAsync = ref.watch(cartSummaryProvider);
    if (cartSummaryAsync.hasValue && cartSummaryAsync.value != null) {
      _cachedCartSummary = cartSummaryAsync.value;
    }
    final cartSummary = _cachedCartSummary ?? cartSummaryAsync.valueOrNull;

    // Delivery settings from backend - using cache preserves previous value across AsyncLoading/refresh
    final deliverySettingsAsync = ref.watch(deliverySettingsProvider);
    if (deliverySettingsAsync.hasValue && deliverySettingsAsync.value != null) {
      _cachedDeliverySettings = deliverySettingsAsync.value;
    }
    final deliverySettings = _cachedDeliverySettings ?? deliverySettingsAsync.valueOrNull;
    final double backendDeliveryFee = deliverySettings?.deliveryFee ?? 30.0;
    final double freeDeliveryThreshold = cartSummary?.freeDeliveryThreshold ??
        (deliverySettings?.freeDeliveryThreshold ?? 499.0);

    // Retrieve store products to populate details - using cache preserves previous products across AsyncLoading/refresh
    final productsAsync = ref.watch(homeProductsProvider);
    if (productsAsync.hasValue && productsAsync.value != null && productsAsync.value!.isNotEmpty) {
      _cachedProducts = productsAsync.value;
    }
    final List<ProductModel> storeProducts =
        _cachedProducts ?? productsAsync.valueOrNull ?? const [];

    // Distinguish initial loading (no items known and initial sync running) from refresh
    final bool isInitialLoading = syncStatus == CartSyncStatus.initialLoading && totalCount == 0;
    final bool isRefreshing = (syncStatus == CartSyncStatus.refreshing ||
            cartSummaryAsync.isRefreshing ||
            productsAsync.isRefreshing ||
            deliverySettingsAsync.isRefreshing) &&
        totalCount > 0;

    // Resolve cart items
    final List<_CartItemData> cartItems = [];
    double calculatedSubtotal = 0.0;

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
      calculatedSubtotal += itemTotal;

      cartItems.add(_CartItemData(
        product: product,
        quantity: quantity,
        itemTotal: itemTotal,
      ));
    }

    final double subtotal = (cartSummary != null && cartSummary.subtotal > 0)
        ? cartSummary.subtotal
        : calculatedSubtotal;
    final double deliveryFee = (cartSummary != null && cartSummary.subtotal > 0)
        ? cartSummary.deliveryFee
        : (subtotal > 0
            ? (subtotal >= freeDeliveryThreshold ? 0.0 : backendDeliveryFee)
            : 0.0);
    final double grandTotal = (cartSummary != null && cartSummary.total > 0)
        ? cartSummary.total
        : (subtotal + deliveryFee);

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
      appBar: AppHeader(
        title: 'Cart',
        showBackButton: false,
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
        foregroundColor: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22.0),
          bottomRight: Radius.circular(22.0),
        ),
      ),
      body: isInitialLoading
          ? _buildInitialLoadingView(isDark)
          : (totalCount == 0 || cartItems.isEmpty
              ? _buildEmptyCartView(isDark)
              : _buildPopulatedCartView(
                  isDark: isDark,
                  isRefreshing: isRefreshing,
                  cartItems: cartItems,
                  totalCount: totalCount,
                  subtotal: subtotal,
                  deliveryFee: deliveryFee,
                  configuredDeliveryFee: backendDeliveryFee,
                  freeDeliveryThreshold: freeDeliveryThreshold,
                  grandTotal: grandTotal,
                )),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isInitialLoading && totalCount > 0 && cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AppButton(
                label: 'Proceed to Checkout',
                variant: ButtonVariant.primary,
                size: ButtonSize.large,
                icon: Icons.arrow_forward_rounded,
                iconPosition: IconPosition.trailing,
                onPressed: _handleProceedToCheckout,
              ),
            ),
          AppBottomNavBar(
            selectedIndex: 2,
            onTabSelected: (index) {
              if (index == 0) {
                GoRouter.of(context).go(RouteNames.home);
              } else if (index == 1) {
                GoRouter.of(context).go(RouteNames.explore);
              } else if (index == 3) {
                try {
                  GoRouter.of(context).push(RouteNames.favorites);
                } catch (_) {
                  // Fallback for standalone tests without GoRouter
                }
              } else if (index == 4) {
                try {
                  GoRouter.of(context).push(RouteNames.profile);
                } catch (_) {
                  // Fallback for standalone tests without GoRouter
                }
              }
            },
          ),
        ],
      ),
    );
  }

  /// Initial Loading View (Screen 12/13 first load)
  Widget _buildInitialLoadingView(bool isDark) {
    return const Center(
      child: AppLoading(
        message: 'Loading your basket...',
      ),
    );
  }

  /// Populated Cart View (Screen 12)
  Widget _buildPopulatedCartView({
    required bool isDark,
    required bool isRefreshing,
    required List<_CartItemData> cartItems,
    required int totalCount,
    required double subtotal,
    required double deliveryFee,
    required double configuredDeliveryFee,
    required double freeDeliveryThreshold,
    required double grandTotal,
  }) {
    final countSubtitle =
        totalCount == 1 ? '1 item in your basket' : '$totalCount items in your basket';
    final bottomInset = 160.0 + MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF014D40),
      backgroundColor: isDark ? AppColors.surfaceContainerDark : Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - bottomInset).clamp(0.0, double.infinity),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isRefreshing)
                      const SizedBox(
                        height: 3.0,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF014D40)),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Page Title & Item Count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cart',
                            style: TextStyle(
                              fontSize: context.sp(26.0),
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              fontFamily: AppTextStyles.fontFamily,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            countSubtitle,
                            style: TextStyle(
                              fontSize: context.sp(14.0),
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              fontFamily: AppTextStyles.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // 3. Cart Items List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          for (int i = 0; i < cartItems.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12.0),
                            _buildCartItemCard(cartItems[i], isDark),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // Flexible spacer that pushes Bill Summary to the bottom on short content (e.g. 1 product)
                    const Spacer(),

                    // 4. Bill Summary Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildBillSummaryCard(
                        isDark: isDark,
                        subtotal: subtotal,
                        deliveryFee: deliveryFee,
                        configuredDeliveryFee: configuredDeliveryFee,
                        freeDeliveryThreshold: freeDeliveryThreshold,
                        grandTotal: grandTotal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Individual Cart Item Card matching 12_Cart.png
  Widget _buildCartItemCard(_CartItemData item, bool isDark) {
    final product = item.product;
    final quantity = item.quantity;

    final unitSubtitle = product.categoryName != null && product.categoryName!.isNotEmpty
        ? '${product.categoryName} • ${product.unit}'
        : product.unit;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              width: context.r(68.0).clamp(56.0, 72.0),
              height: context.r(68.0).clamp(56.0, 72.0),
              color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackThumbnail(isDark),
                    )
                  : _buildFallbackThumbnail(isDark),
            ),
          ),

          const SizedBox(width: 12.0),

          // Middle Details: Name, Unit, Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.sp(15.5),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  unitSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.sp(12.5),
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  CurrencyFormatter.format(product.price),
                  style: TextStyle(
                    fontSize: context.sp(17.0),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF014D40),
                    fontFamily: AppTextStyles.fontFamily,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8.0),

          // Right Column: Remove 'X' Button + Quantity Controller
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remove 'X' Button
              GestureDetector(
                onTap: () => _handleRemoveItem(product.id, product.name),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.0,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  ),
                ),
              ),

              const SizedBox(height: 14.0),

              // Reused Shared ProductQuantityControl
              ProductQuantityControl(
                quantity: quantity,
                collapsedWidth: 32.0,
                expandedWidth: 84.0,
                height: 32.0,
                onIncrement: () {
                  ref.read(cartNotifierProvider.notifier).increment(product.id);
                },
                onDecrement: () {
                  ref.read(cartNotifierProvider.notifier).decrement(product.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackThumbnail(bool isDark) {
    return Center(
      child: Icon(
        Icons.eco_rounded,
        size: 30.0,
        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF014D40),
      ),
    );
  }

  /// Bill Breakdown Card matching 12_Cart.png
  Widget _buildBillSummaryCard({
    required bool isDark,
    required double subtotal,
    required double deliveryFee,
    required double configuredDeliveryFee,
    required double freeDeliveryThreshold,
    required double grandTotal,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Subtotal Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: context.sp(14.5),
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
              Text(
                CurrencyFormatter.format(subtotal),
                style: TextStyle(
                  fontSize: context.sp(14.5),
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          // Delivery Fee Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Delivery Fee',
                    style: TextStyle(
                      fontSize: context.sp(14.5),
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  GestureDetector(
                    key: const ValueKey('cart_delivery_fee_info_icon'),
                    onTap: () => _showDeliveryFeeInfoSheet(
                      context,
                      configuredDeliveryFee,
                      freeDeliveryThreshold,
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 16.0,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                deliveryFee == 0.0 ? 'FREE' : CurrencyFormatter.format(deliveryFee),
                style: TextStyle(
                  fontSize: context.sp(14.5),
                  fontWeight: FontWeight.w700,
                  color: deliveryFee == 0.0
                      ? const Color(0xFF16A34A)
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14.0),

          // Divider
          Divider(
            height: 1.0,
            thickness: 1.0,
            color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          ),

          const SizedBox(height: 14.0),

          // Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: context.sp(17.0),
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
              Text(
                CurrencyFormatter.format(grandTotal),
                style: TextStyle(
                  fontSize: context.sp(22.0),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF014D40),
                  fontFamily: AppTextStyles.fontFamily,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Empty Cart View (Screen 13) matching 13_Cart_Empty.png
  Widget _buildEmptyCartView(bool isDark) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF014D40),
      backgroundColor: isDark ? AppColors.surfaceContainerDark : Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 24.0,
                  bottom: 80.0 + bottomInset,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Empty Basket Illustration / Icon
                    Container(
                      width: context.r(130.0),
                      height: context.r(130.0),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceContainerDark
                            : const Color(0xFF014D40).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.shopping_basket_outlined,
                          size: context.r(60.0),
                          color: const Color(0xFF014D40),
                        ),
                      ),
                    ),

                    SizedBox(height: context.h(24.0)),

                    // 2. "Your cart is empty" Title
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: context.sp(22.0),
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                    ),

                    const SizedBox(height: 8.0),

                    // 3. Description Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Add fresh fruits and vegetables to your cart.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                        fontSize: context.sp(14.5),
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        fontFamily: AppTextStyles.fontFamily,
                        height: 1.4,
                      ),
                    ),
                  ),

                  SizedBox(height: context.h(28.0)),

                  // 4. "Start Shopping" CTA Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: AppButton(
                      label: 'Start Shopping',
                      variant: ButtonVariant.primary,
                      size: ButtonSize.large,
                      icon: Icons.shopping_bag_outlined,
                      iconPosition: IconPosition.leading,
                      onPressed: _handleStartShopping,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
    );
  }
}

/// Helper data holder for resolved cart items
class _CartItemData {
  final ProductModel product;
  final int quantity;
  final double itemTotal;

  const _CartItemData({
    required this.product,
    required this.quantity,
    required this.itemTotal,
  });
}
