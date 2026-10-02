import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/checkout_bar.dart';
import '../../../address/presentation/providers/customer_address_provider.dart';
import '../../../home/data/models/category_model.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../home/presentation/widgets/home_header.dart';
import '../../../profile_setup/presentation/providers/customer_profile_provider.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../widgets/explore_category_card.dart';

/// Screen 09 — Explore / Category Listing for Unique Basket.
///
/// Implements the approved 09_Category_Listing design specification:
/// - Brand green collapsing App Header with address, distance pill, and search bar.
/// - Prominent "Categories" section heading.
/// - 2-column responsive Grid of real backend categories (`GET /categories`).
/// - Preserves backend display order without manual sorting.
/// - Loading skeleton, empty state, and error state handling.
/// - Explore bottom-nav item active (index 1).
/// - Category tap navigation to [RouteNames.categoryProducts] with `categoryId`.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;

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

    final servingStoreAsync = ref.watch(servingStoreProvider);
    final servingStore = servingStoreAsync.asData?.value;
    final String? distanceText =
        formatStoreDistance(servingStore?.distanceKm);

    final categoriesAsync = ref.watch(homeCategoriesProvider);
    ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final int totalCartCount = cartNotifier.totalItemCount;

    final allStoreProducts = (servingStore != null && servingStore.id.isNotEmpty)
        ? (ref.watch(storeProductsProvider(servingStore.id)).asData?.value ??
            const <ProductModel>[])
        : const <ProductModel>[];
    final double totalCartPrice = cartNotifier.calculateTotal(allStoreProducts);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFF014D40),
            edgeOffset: topPadding + 178.0,
            onRefresh: () async {
              ref.invalidate(customerProfileProvider);
              ref.invalidate(customerAddressesProvider);
              ref.invalidate(defaultCustomerAddressProvider);
              ref.invalidate(servingStoreProvider);
              ref.invalidate(nearbyStoresProvider);
              ref.invalidate(homeCategoriesProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Pinned collapsible Brand Header
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
              // "Categories" Section Heading
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 18.0,
                    bottom: 14.0,
                  ),
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: context.sp(22),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),

              // Categories Grid / Loading / Empty / Error States
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: Icons.category_outlined,
                        title: 'No Categories Found',
                        message: 'Please check back soon for fresh produce categories.',
                        actionText: 'Refresh',
                        onAction: () => ref.refresh(homeCategoriesProvider),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = categories[index];
                          const categoryColors = [
                            Color(0xFFEA580C), // Warm Orange / Red
                            Color(0xFF16A34A), // Fresh Green
                            Color(0xFF0284C7), // Sky Blue
                          ];
                          final itemColor = categoryColors[index % categoryColors.length];
                          return ExploreCategoryCard(
                            id: category.id,
                            name: category.name,
                            imageUrl: category.imageUrl,
                            color: itemColor,
                            onTap: () => _handleCategoryTap(category),
                          );
                        },
                        childCount: categories.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildSkeletonCard(isDark, context),
                      childCount: 4,
                    ),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorState(
                    message: 'Failed to load categories. Please check your connection.',
                    onRetry: () => ref.refresh(homeCategoriesProvider),
                  ),
                ),
              ),

              // Bottom padding for floating navigation bar and checkout bar clearance
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
                  child: CheckoutBar(
                    itemCount: totalCartCount,
                    totalPrice: totalCartPrice,
                    onCheckoutTap: () {
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
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: 1, // Explore is active (Tab 1)
        onTabSelected: (index) {
          if (index == 0) {
            GoRouter.of(context).go(RouteNames.home);
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
          }
        },
      ),

    );
  }

  Widget _buildSkeletonCard(bool isDark, BuildContext context) {
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
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: context.r(138),
                height: context.r(138),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          Container(
            width: context.r(90),
            height: context.r(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardBorderDark : const Color(0xFFF1F5F9),
              borderRadius: AppRadius.rXs,
            ),
          ),
        ],
      ),
    );
  }
}
