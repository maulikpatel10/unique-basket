import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_product_card.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/checkout_bar.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../store/presentation/providers/store_provider.dart';

/// Screen 10 — Category Product Listing.
/// Displays store-specific products filtered by [categoryId], composed strictly from shared widgets.
class CategoryProductListingScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductListingScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryProductListingScreen> createState() =>
      _CategoryProductListingScreenState();
}

class _CategoryProductListingScreenState
    extends ConsumerState<CategoryProductListingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    final availableProducts = products.where((p) => p.isPurchasable).toList();
    final cleanQuery = _searchQuery.trim().toLowerCase();
    if (cleanQuery.isEmpty) return availableProducts;
    return availableProducts.where((p) {
      final nameMatch = p.name.toLowerCase().contains(cleanQuery);
      final descMatch =
          p.description?.toLowerCase().contains(cleanQuery) ?? false;
      final unitMatch = p.unit.toLowerCase().contains(cleanQuery);
      return nameMatch || descMatch || unitMatch;
    }).toList();
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

    final servingStoreAsync = ref.watch(servingStoreProvider);
    final productsAsync = ref.watch(categoryProductsProvider(widget.categoryId));
    final cart = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final favorites = ref.watch(favoritesNotifierProvider);

    final int totalCartCount = cartNotifier.totalItemCount;
    final servingStore = servingStoreAsync.asData?.value;
    final productsList = productsAsync.asData?.value ?? const <ProductModel>[];
    final allStoreProducts = (servingStore != null && servingStore.id.isNotEmpty)
        ? (ref.watch(storeProductsProvider(servingStore.id)).asData?.value ??
            const <ProductModel>[])
        : const <ProductModel>[];
    final combinedProducts = {
      ...productsList,
      ...allStoreProducts,
    }.toList();
    final double totalCartPrice = cartNotifier.calculateTotal(combinedProducts);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final title = widget.categoryName.isNotEmpty
        ? widget.categoryName
        : 'Products';

    return PopScope(
      canPop: !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppHeader(
          title: title,
          centerTitle: false,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
          foregroundColor: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          onBackTap: () {
            if (_searchFocusNode.hasFocus) {
              _searchFocusNode.unfocus();
              return;
            }
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              GoRouter.of(context).go(RouteNames.explore);
            }
          },
          bottomHeight: context.r(64),
          bottom: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: AppSearchBar(
              readOnly: false,
              controller: _searchController,
              focusNode: _searchFocusNode,
              height: context.r(48),
              isGlass: true,
              onSubmitted: (value) {
                _searchFocusNode.unfocus();
              },
              trailing: _searchController.text.isNotEmpty
                  ? IconButton(
                      key: const Key('category_search_clear_button'),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF0F172A),
                        size: 20.0,
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36.0,
                        minHeight: 36.0,
                      ),
                    )
                  : null,
              onTrailingTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voice search coming soon.'),
                    duration: Duration(milliseconds: 600),
                  ),
                );
              },
            ),
          ),
        ),
        body: Stack(
          children: [
            servingStoreAsync.when(
          data: (servingStore) {
            if (servingStore == null || servingStore.id.isEmpty) {
              return const AppEmptyState(
                icon: Icons.storefront_outlined,
                title: 'No Serving Store',
                message:
                    'Delivery is currently unavailable for your selected location.',
              );
            }

            return productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No Products',
                    message: 'No products available in this category.',
                  );
                }

                final filtered = _filterProducts(products);

                if (filtered.isEmpty) {
                  final categoryLabel = widget.categoryName.trim().isNotEmpty
                      ? widget.categoryName.trim().toLowerCase()
                      : 'products';
                  return AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No $categoryLabel found',
                    message: 'Try a different search term.',
                    actionText: 'Clear Search',
                    onAction: () {
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                    },
                  );
                }

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 14.0,
                        mainAxisExtent: context.r(112) + 108.0,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = filtered[index];
                          final quantity = cart[product.id] ?? 0;
                          final isFavorite = favorites.contains(product.id);

                          return AppProductCard(
                            id: product.id,
                            name: product.name,
                            price: product.price,
                            unit: product.unit,
                            oldPrice: product.mrp,
                            badge: product.resolvedBadge,
                            imageUrl: product.imageUrl,
                            quantity: quantity,
                            isFavorite: isFavorite,
                            isPurchasable: product.isPurchasable,
                            onAddToCart: () {
                              ref
                                  .read(cartNotifierProvider.notifier)
                                  .increment(product.id);
                            },
                            onIncrement: () {
                              ref
                                  .read(cartNotifierProvider.notifier)
                                  .increment(product.id);
                            },
                            onDecrement: () {
                              ref
                                  .read(cartNotifierProvider.notifier)
                                  .decrement(product.id);
                            },
                            onToggleFavorite: () {
                              ref
                                  .read(favoritesNotifierProvider.notifier)
                                  .toggleFavorite(product.id);
                            },
                            onTap: () {
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
                        childCount: filtered.length,
                      ),
                    ),
                  ),

                  // Bottom clearance for floating navigation bar and checkout bar
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: totalCartCount > 0
                          ? (150.0 + (bottomInset > 0 ? bottomInset : 12.0))
                          : (90.0 + (bottomInset > 0 ? bottomInset : 12.0)),
                    ),
                  ),
                ],
              );
            },
            loading: () => const AppLoading(message: 'Loading products...'),
            error: (err, _) => AppErrorState(
              message:
                  'Failed to load category products. Please check your connection.',
              onRetry: () => ref.refresh(
                categoryProductsProvider(widget.categoryId),
              ),
            ),
          );
        },
        loading: () => const AppLoading(message: 'Connecting to store...'),
        error: (err, _) => AppErrorState(
          message: 'Failed to resolve store. Please check your connection.',
          onRetry: () => ref.refresh(servingStoreProvider),
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
                    onCheckoutTap: _handleCheckoutTap,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: 1, // Explore remains active
        onTabSelected: (index) {
          if (index == 0) {
            GoRouter.of(context).go(RouteNames.home);
          } else if (index == 1) {
            GoRouter.of(context).go(RouteNames.explore);
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
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile tab selected'),
                duration: Duration(milliseconds: 800),
              ),
            );
          }
        },
      ),
    ),
  );
}
}
