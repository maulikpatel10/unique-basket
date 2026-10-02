import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../address/presentation/providers/customer_address_provider.dart';
import '../../../profile_setup/presentation/providers/customer_profile_provider.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../providers/home_provider.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/home_bottom_nav_bar.dart';
import '../widgets/home_cart_floating_bar.dart';
import '../widgets/home_categories_section.dart';
import '../widgets/home_header.dart';
import '../widgets/home_products_section.dart';

/// Screen 08 — Home for Unique Basket Customer App.
///
/// Accurately reproduces the approved 08_Home design reference:
/// - Top App Header with Delivering to (Live Address + Dropdown) and Notification icon
/// - Rounded Search Bar with microphone action icon
/// - Promotional Hero Banner Carousel with "Fresh Harvest" tag, headline, and "Shop Now →" CTA + indicator dots
/// - "Explore Categories" section with circular category items (Fruits, Vegetables, Exotics, Organic)
/// - "Fresh Arrivals" section with 2-column product grid, discount/tag badges, wishlist favorites, and dynamic add/quantity selector
/// - Floating Cart Summary bar with item count, total price, and Checkout action
/// - 5-tab Bottom Navigation Bar (Shop, Explore, Cart, Favorite, Profile)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _handleAddressTap() {
    final defaultAddress =
        ref.read(defaultCustomerAddressProvider).asData?.value;
    if (defaultAddress != null) {
      final title = (defaultAddress['title'] as String?)?.trim() ?? 'Home';
      final line = (defaultAddress['addressLine'] as String?)?.trim() ??
          (defaultAddress['city'] as String?)?.trim() ??
          '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Delivering to: $title${line.isNotEmpty ? ' - $line' : ''}'),
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
      // Fallback for standalone tests without GoRouter
    }
  }

  void _handleViewAllCategories() {
    try {
      GoRouter.of(context).go(RouteNames.explore);
    } catch (_) {
      // Fallback for standalone tests without GoRouter
    }
  }

  void _handleCategoryTap(CategoryModel category) {
    try {
      final uri = Uri(
        path: RouteNames.categoryProducts,
        queryParameters: {
          'categoryId': category.id,
          'categoryName': category.name,
        },
      ).toString();
      GoRouter.of(context).push(uri);
    } catch (_) {
      // Fallback if GoRouter is not available in standalone tests
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected category: ${category.name} (${category.id})'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleCheckoutTap() {
    try {
      GoRouter.of(context).push(RouteNames.checkout);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proceeding to Checkout...'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF014D40),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch live customer profile & default address providers
    ref.watch(customerProfileProvider);
    final defaultAddressAsync = ref.watch(defaultCustomerAddressProvider);

    final addressData = defaultAddressAsync.asData?.value;
    final isLoadingAddress = defaultAddressAsync.isLoading;
    final hasAddressError = defaultAddressAsync.hasError;

    final String deliveryTitle;
    final String deliveryAddress;

    if (isLoadingAddress && addressData == null) {
      deliveryTitle = 'Loading...';
      deliveryAddress = '';
    } else if (addressData != null) {
      deliveryTitle = (addressData['title'] as String?)?.trim() ?? 'Home';
      final line = (addressData['addressLine'] as String?)?.trim() ?? '';
      final locality = (addressData['areaLocality'] as String?)?.trim() ?? '';
      final city = (addressData['city'] as String?)?.trim() ?? '';

      if (line.isNotEmpty) {
        deliveryAddress = line;
      } else if (locality.isNotEmpty && city.isNotEmpty) {
        deliveryAddress = '$locality, $city';
      } else if (city.isNotEmpty) {
        deliveryAddress = city;
      } else {
        deliveryAddress = locality;
      }
    } else if (hasAddressError) {
      deliveryTitle = 'Delivery Address';
      deliveryAddress = 'Tap to retry';
    } else {
      deliveryTitle = 'Select Location';
      deliveryAddress = 'Tap to add address';
    }

    final categoriesAsync = ref.watch(homeCategoriesProvider);
    final productsAsync = ref.watch(homeProductsProvider);
    final bannersAsync = ref.watch(homeBannersProvider);

    // Watch serving store resolution for real distance calculation
    final servingStoreAsync = ref.watch(servingStoreProvider);
    final servingStore = servingStoreAsync.asData?.value;
    final String? storeDistanceText =
        formatStoreDistance(servingStore?.distanceKm);

    final cartQuantities = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final favoriteIds = ref.watch(favoritesNotifierProvider);
    final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);

    final List<ProductModel> productsList =
        productsAsync.asData?.value ?? const [];
    final int totalCartCount = cartNotifier.totalItemCount;
    final double totalCartPrice = cartNotifier.calculateTotal(productsList);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
      body: Stack(
        children: [
          // Main Scrollable Content with Pinned Collapsing Header
          RefreshIndicator(
            color: const Color(0xFF014D40),
            edgeOffset: MediaQuery.paddingOf(context).top + 178.0,
            onRefresh: () async {
              ref.invalidate(customerProfileProvider);
              ref.invalidate(customerAddressesProvider);
              ref.invalidate(servingStoreProvider);
              ref.invalidate(nearbyStoresProvider);
              ref.invalidate(homeCategoriesProvider);
              ref.invalidate(homeProductsProvider);
              ref.invalidate(homeBannersProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Pinned Collapsing Header with Search Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HomeHeaderSliverDelegate(
                    topPadding: MediaQuery.paddingOf(context).top,
                    deliveryTitle: deliveryTitle,
                    deliveryAddress: deliveryAddress,
                    distanceText: storeDistanceText,
                    onAddressTap: _handleAddressTap,
                    onNotificationTap: _handleNotificationTap,
                    onSearchTap: _handleSearchTap,
                  ),
                ),

                // 2. Promotional Hero Banner Carousel
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _entranceFade,
                    child: SlideTransition(
                      position: _entranceSlide,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: bannersAsync.when(
                          data: (banners) => HomeBannerCarousel(
                            banners: banners,
                            onBannerTap: (banner) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Promo: ${banner.tag} selected'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          loading: () => Container(
                            height: 154,
                            margin: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceContainerDark
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF014D40),
                              ),
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Explore Categories Section
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _entranceFade,
                    child: SlideTransition(
                      position: _entranceSlide,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: categoriesAsync.when(
                          data: (categories) {
                            if (categories.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return HomeCategoriesSection(
                              categories: categories,
                              onViewAllTap: _handleViewAllCategories,
                              onCategoryTap: _handleCategoryTap,
                            );
                          },
                          loading: () => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 140,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfaceContainerDark
                                        : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  height: 112,
                                  child: Row(
                                    children: List.generate(
                                      4,
                                      (index) => Container(
                                        width: 68,
                                        height: 68,
                                        margin:
                                            const EdgeInsets.only(right: 14.0),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark
                                              ? AppColors.surfaceContainerDark
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Fresh Arrivals Products Grid Section
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _entranceFade,
                    child: SlideTransition(
                      position: _entranceSlide,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: productsAsync.when(
                          data: (products) {
                            final purchasableProducts =
                                products.where((p) => p.isPurchasable).toList();
                            if (purchasableProducts.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return HomeProductsSection(
                              title: 'Fresh Arrivals',
                              products: purchasableProducts,
                              cartQuantities: cartQuantities,
                              favoriteIds: favoriteIds,
                              onAddToCart: (product) =>
                                  cartNotifier.increment(product.id),
                              onIncrement: (product) =>
                                  cartNotifier.increment(product.id),
                              onDecrement: (product) =>
                                  cartNotifier.decrement(product.id),
                              onToggleFavorite: (product) =>
                                  favoritesNotifier.toggleFavorite(product.id),
                              onProductTap: (product) {
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
                                } catch (_) {}
                              },
                            );
                          },
                          loading: () => _buildProductsLoadingSkeleton(isDark),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Space for floating glass bottom nav and checkout bar
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: totalCartCount > 0
                        ? (150.0 + (bottomInset > 0 ? bottomInset : 12.0))
                        : (90.0 + (bottomInset > 0 ? bottomInset : 12.0)),
                  ),
                ),
              ],
            ),
          ),

          // Floating Cart Bar (Smooth animated entrance above bottom navigation)
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
                  child: HomeCartFloatingBar(
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
      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: _selectedTabIndex,
        onTabSelected: (index) {
          if (index == 1) {
            try {
              GoRouter.of(context).go(RouteNames.explore);
            } catch (_) {
              // Fallback for standalone tests without GoRouter
            }
          } else if (index == 2) {
            try {
              GoRouter.of(context).push(RouteNames.cart);
            } catch (_) {
              // Fallback for standalone tests without GoRouter
            }
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
          } else {
            setState(() {
              _selectedTabIndex = index;
            });
          }
        },
      ),

    );
  }

  Widget _buildProductsLoadingSkeleton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 130,
            height: 20,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceContainerDark
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6.0),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = (constraints.maxWidth - 12.0) / 2;
              return Wrap(
                spacing: 12.0,
                runSpacing: 14.0,
                children: List.generate(
                  4,
                  (index) => Container(
                    width: cardWidth,
                    height: 212.0,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: isDark
                            ? AppColors.cardBorderDark
                            : const Color(0xFFE2E8F0),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 112.0,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceContainerDark
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Container(
                          width: cardWidth * 0.7,
                          height: 14.0,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceContainerDark
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Container(
                          width: cardWidth * 0.4,
                          height: 12.0,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceContainerDark
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 45.0,
                              height: 16.0,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceContainerDark
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            Container(
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.surfaceContainerDark
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
