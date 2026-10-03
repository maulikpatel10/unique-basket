import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../address/presentation/providers/customer_address_provider.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../home/presentation/widgets/home_header.dart';
import '../../../store/presentation/providers/store_provider.dart';

/// Screen 14 — Favourites (and Screen 15 — Empty Favourites) for Unique Basket Customer App.
///
/// Implements the approved 14_Favourites & 15_Favourites_Empty design specifications:
/// - Top Delivery / Search Header matching Home and Explore.
/// - Dynamic section heading "Favourites" with real-time "{n} items" count.
/// - Responsive 2-column grid using the canonical [AppProductCard].
/// - Instant real-time favourite toggling with immediate list update via [favoritesNotifierProvider].
/// - Seamless transition to Screen 15 Empty State when no products are favorited.
/// - Out-of-stock product guard showing "This item is currently out of stock." toast.
/// - Floating [CheckoutBar] with animated entry when cart contains items.
/// - Floating [AppBottomNavBar] with Index 3 (Favorite) active.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  void _handleAddressTap() {
    final defaultAddress = ref.read(defaultCustomerAddressProvider).asData?.value;
    if (defaultAddress != null) {
      final title = (defaultAddress['title'] as String?)?.trim() ?? 'Home';
      final line = (defaultAddress['addressLine'] as String?)?.trim() ??
          (defaultAddress['city'] as String?)?.trim() ??
          '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivering to: $title${line.isNotEmpty ? ' - $line' : ''}'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF014D40),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a delivery address.'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF014D40),
        ),
      );
    }
  }

  void _handleNotificationTap() {
    try {
      GoRouter.of(context).push(RouteNames.notifications);
    } catch (_) {
      // Standalone widget test fallback
    }
  }


  void _handleSearchTap() {
    try {
      GoRouter.of(context).push(RouteNames.search);
    } catch (_) {
      // Fallback for standalone test harness
    }
  }

  void _handleExploreProducts() {
    try {
      GoRouter.of(context).go(RouteNames.explore);
    } catch (_) {
      // Fallback for standalone test harness
    }
  }

  void _handleCheckoutTap() {
    try {
      GoRouter.of(context).push(RouteNames.checkout);
    } catch (_) {
      // Fallback for standalone test harness
    }
  }

  void _handleProductTap(ProductModel product) {
    if (!product.isPurchasable) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item is currently out of stock.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final uri = Uri(
        path: RouteNames.productDetails,
        queryParameters: {'productId': product.id},
      ).toString();
      GoRouter.of(context).push(uri, extra: product);
    } catch (_) {
      // Fallback for standalone test harness
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Delivery address resolution
    final defaultAddressAsync = ref.watch(defaultCustomerAddressProvider);
    String deliveryTitle = 'Home';
    String deliveryAddress = '';
    defaultAddressAsync.whenData((addr) {
      if (addr != null) {
        deliveryTitle = (addr['title'] as String?)?.trim() ?? 'Home';
        final locality = (addr['areaLocality'] as String?)?.trim() ?? '';
        final city = (addr['city'] as String?)?.trim() ?? '';
        deliveryAddress = locality.isNotEmpty ? '$locality, $city' : city;
      }
    });

    // Serving store & distance resolution
    final servingStoreAsync = ref.watch(servingStoreProvider);
    String? distanceText;
    servingStoreAsync.whenData((store) {
      if (store != null) {
        distanceText = formatStoreDistance(store.distanceKm);
      }
    });

    // Favorites & Cart state
    final favoriteIds = ref.watch(favoritesNotifierProvider);
    final cart = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final int totalCartCount = cartNotifier.totalItemCount;

    // Products resolution
    final productsAsync = ref.watch(homeProductsProvider);

    return productsAsync.when(
      data: (products) {
        final favoriteProducts = products
            .where((p) => favoriteIds.contains(p.id) && p.isPurchasable)
            .toList();

        final double totalCartPrice = cartNotifier.calculateTotal(products);

        if (favoriteProducts.isEmpty) {
          return _buildEmptyFavoritesScaffold(isDark);
        }

        return _buildPopulatedFavoritesScaffold(
          isDark: isDark,
          topPadding: topPadding,
          bottomInset: bottomInset,
          deliveryTitle: deliveryTitle,
          deliveryAddress: deliveryAddress,
          distanceText: distanceText,
          favoriteProducts: favoriteProducts,
          cart: cart,
          totalCartCount: totalCartCount,
          totalCartPrice: totalCartPrice,
        );
      },
      loading: () => Scaffold(
        extendBody: false,
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppHeader(
          title: 'Favourites',
          showBackButton: false,
          centerTitle: true,
          backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
          foregroundColor: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22.0),
            bottomRight: Radius.circular(22.0),
          ),
        ),
        body: const Center(
          child: AppLoading(message: 'Loading your favourites...'),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
      error: (err, _) => Scaffold(
        extendBody: false,
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppHeader(
          title: 'Favourites',
          showBackButton: false,
          centerTitle: true,
          backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
          foregroundColor: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22.0),
            bottomRight: Radius.circular(22.0),
          ),
        ),
        body: Center(
          child: AppErrorState(
            message: 'Failed to load products. Please check your connection.',
            onRetry: () => ref.refresh(homeProductsProvider),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  /// Screen 14 — Populated Favourites View matching 14_Favourites.png
  Widget _buildPopulatedFavoritesScaffold({
    required bool isDark,
    required double topPadding,
    required double bottomInset,
    required String deliveryTitle,
    required String deliveryAddress,
    required String? distanceText,
    required List<ProductModel> favoriteProducts,
    required Map<String, double> cart,
    required int totalCartCount,
    required double totalCartPrice,
  }) {
    final countSubtitle = favoriteProducts.length == 1
        ? '1 item'
        : '${favoriteProducts.length} items';

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. Pinned Collapsing Delivery & Search Header
              SliverPersistentHeader(
                pinned: true,
                delegate: HomeHeaderSliverDelegate(
                  topPadding: topPadding,
                  deliveryTitle: deliveryTitle,
                  deliveryAddress: deliveryAddress,
                  distanceText: distanceText,
                  onAddressTap: _handleAddressTap,
                  onNotificationTap: _handleNotificationTap,
                  onSearchTap: _handleSearchTap,
                  onMicTap: _handleSearchTap,
                ),
              ),

              // 2. Section Heading "Favourites" & "{n} items"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favourites',
                        style: TextStyle(
                          fontSize: context.sp(26.0),
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF014D40),
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
              ),

              // 3. 2-Column Responsive Product Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 14.0,
                    mainAxisExtent: context.r(112) + 108.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = favoriteProducts[index];
                      final quantity = cart[product.id] ?? 0;

                      return AppProductCard(
                        id: product.id,
                        name: product.name,
                        price: product.price,
                        unit: product.unit,
                        oldPrice: product.mrp,
                        badge: product.resolvedBadge,
                        imageUrl: product.imageUrl,
                        quantity: quantity,
                        canIncrement: product.quantityRule.canIncrement(quantity),
                        isFavorite: true,
                        isPurchasable: product.isPurchasable,
                        onAddToCart: () {
                          ref.read(cartNotifierProvider.notifier).increment(product.id, rule: product.quantityRule);
                        },
                        onIncrement: () {
                          ref.read(cartNotifierProvider.notifier).increment(product.id, rule: product.quantityRule);
                        },
                        onDecrement: () {
                          ref.read(cartNotifierProvider.notifier).decrement(product.id, rule: product.quantityRule);
                        },
                        onToggleFavorite: () {
                          ref.read(favoritesNotifierProvider.notifier).toggleFavorite(product.id);
                        },
                        onTap: () => _handleProductTap(product),
                      );
                    },
                    childCount: favoriteProducts.length,
                  ),
                ),
              ),

              // 4. Bottom clearance for floating navigation bar and checkout bar
              SliverToBoxAdapter(
                child: SizedBox(
                  height: totalCartCount > 0
                      ? (150.0 + (bottomInset > 0 ? bottomInset : 12.0))
                      : (90.0 + (bottomInset > 0 ? bottomInset : 12.0)),
                ),
              ),
            ],
          ),

          // Floating Checkout Bar (Smooth animated entrance above bottom navigation)
          Positioned(
            left: 0,
            right: 0,
            bottom: 74.0 + (bottomInset > 0 ? bottomInset : 12.0),
            child: AnimatedSlide(
              offset: totalCartCount > 0 ? Offset.zero : const Offset(0, 0.6),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: totalCartCount > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: IgnorePointer(
                  ignoring: totalCartCount == 0,
                  child: CheckoutBar(
                    itemCount: totalCartCount,
                    totalPrice: totalCartPrice,
                    onCheckoutTap: _handleCheckoutTap,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Screen 15 — Empty Favourites View matching 15_Favourites_Empty.png
  Widget _buildEmptyFavoritesScaffold(bool isDark) {
    return Scaffold(
      extendBody: false,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppHeader(
        title: 'Favourites',
        showBackButton: false,
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
        foregroundColor: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22.0),
          bottomRight: Radius.circular(22.0),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Empty Heart Illustration Container
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
                    Icons.favorite_rounded,
                    size: context.r(60.0),
                    color: const Color(0xFF014D40),
                  ),
                ),
              ),

              SizedBox(height: context.h(24.0)),

              // 2. Headline
              Text(
                'No favourites yet',
                style: TextStyle(
                  fontSize: context.sp(22.0),
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),

              const SizedBox(height: 8.0),

              // 3. Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Save products you love and find them here for quick ordering.',
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

              // 4. "Explore Products" CTA Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AppButton(
                  label: 'Explore Products',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.large,
                  icon: Icons.storefront_outlined,
                  iconPosition: IconPosition.leading,
                  onPressed: _handleExploreProducts,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Floating Glass Bottom Navigation Bar with Index 3 (Favorite) Selected
  Widget _buildBottomNavigationBar() {
    return AppBottomNavBar(
      selectedIndex: 3,
      onTabSelected: (index) {
        if (index == 0) {
          GoRouter.of(context).go(RouteNames.home);
        } else if (index == 1) {
          GoRouter.of(context).go(RouteNames.explore);
        } else if (index == 2) {
          try {
            GoRouter.of(context).push(RouteNames.cart);
          } catch (_) {}
        } else if (index == 4) {
          try {
            GoRouter.of(context).push(RouteNames.profile);
          } catch (_) {}
        }
      },
    );

  }
}
