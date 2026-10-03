import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/search_no_results_card.dart';
import '../widgets/search_query_suggestion_item.dart';
import '../widgets/search_suggestion_row.dart';

/// Comprehensive Search Feature covering Screen 17, Screen 18, and Screen 19.
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({
    super.key,
    this.initialQuery,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  String _currentQuery = '';
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: initial);
    _searchFocusNode = FocusNode();
    _currentQuery = initial.trim();
    _isSubmitted = false;

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _currentQuery) {
      setState(() {
        _currentQuery = query;
        if (_isSubmitted) {
          _isSubmitted = false;
        }
      });
    }
  }

  void _handleSubmit(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    setState(() {
      _currentQuery = clean;
      _isSubmitted = true;
    });

    _searchFocusNode.unfocus();
    ref.read(recentSearchesProvider.notifier).addSearch(clean);
  }

  void _selectAndSubmitSearch(String query) {
    _searchController.text = query;
    _handleSubmit(query);
  }

  void _handleClearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
      _isSubmitted = false;
    });
    _searchFocusNode.requestFocus();
  }

  void _handleVoiceSearch() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice search coming soon.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleFilterTap() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Advanced filters coming soon.'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      // Fallback
    }
  }

  void _handleCheckoutTap() {
    try {
      GoRouter.of(context).push(RouteNames.checkout);
    } catch (_) {
      // Fallback
    }
  }

  void _handleBottomNavTap(int index) {
    if (index == 0) {
      GoRouter.of(context).go(RouteNames.home);
    } else if (index == 1) {
      GoRouter.of(context).go(RouteNames.explore);
    } else if (index == 2) {
      GoRouter.of(context).push(RouteNames.cart);
    } else if (index == 3) {
      GoRouter.of(context).go(RouteNames.favorites);
    } else if (index == 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile (Screen 20) coming soon.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final productsAsync = ref.watch(homeProductsProvider);
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    final cartMap = ref.watch(cartNotifierProvider);
    final favoritesSet = ref.watch(favoritesNotifierProvider);

    // D-012: the cart badge counts product lines, not total quantity
    final totalCartCount = cartMap.length;
    final allProducts = productsAsync.value ?? [];
    final cartTotal = ref.read(cartNotifierProvider.notifier).calculateTotal(allProducts);

    return PopScope(
      canPop: !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // 1. Top Green Search Bar Header Container
              _buildTopHeader(context, isDark),

              // 2. Main Search Body
              Expanded(
                child: productsAsync.when(
                  loading: () => const Center(child: AppLoading()),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48.0,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12.0),
                          Text(
                            'Unable to load catalog.',
                            style: TextStyle(
                              fontSize: context.sp(16.0),
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              fontFamily: AppTextStyles.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (products) {
                    if (_currentQuery.isEmpty) {
                      return _buildEmptyQueryView(context, isDark);
                    }

                    if (!_isSubmitted) {
                      // Screen 17: Live Suggestions View
                      return _buildSuggestionsView(context, isDark, cartMap);
                    }

                    // Submitted State: Check Results
                    final results = ref.watch(searchResultsProvider(_currentQuery));

                    if (results.isEmpty) {
                      // Screen 19: Search No Results View
                      return SearchNoResultsCard(
                        query: _currentQuery,
                        onSearchAgain: _handleClearSearch,
                      );
                    }

                    // Screen 18: Search Results View
                    return _buildSearchResultsGrid(
                      context: context,
                      isDark: isDark,
                      results: results,
                      categories: categoriesAsync.value ?? [],
                      cartMap: cartMap,
                      favoritesSet: favoritesSet,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (totalCartCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: CheckoutBar(
                  itemCount: totalCartCount,
                  totalPrice: cartTotal,
                  onCheckoutTap: _handleCheckoutTap,
                ),
              ),
            AppBottomNavBar(
              selectedIndex: 1, // Highlight Explore / Search tab
              onTabSelected: _handleBottomNavTap,
            ),
          ],
        ),
      ),
    );
  }

  /// Top Deep Green Header Container matching Screen 17/18/19.
  Widget _buildTopHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8.0,
        left: 12.0,
        right: 12.0,
        bottom: 14.0,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF014D40),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22.0),
          bottomRight: Radius.circular(22.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row with Back Button & Title
          Row(
            children: [
              IconButton(
                key: const Key('search_back_button'),
                onPressed: () {
                  if (_searchFocusNode.hasFocus) {
                    _searchFocusNode.unfocus();
                    return;
                  }
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    GoRouter.of(context).go(RouteNames.home);
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24.0,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40.0,
                  minHeight: 40.0,
                ),
              ),
              const SizedBox(width: 4.0),
              Text(
                'Search',
                style: TextStyle(
                  fontSize: context.sp(20.0),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Search Bar Input
          AppSearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: widget.initialQuery == null || widget.initialQuery!.isEmpty,
            readOnly: false,
            hintText: 'Search for fresh fruits, veggies...',
            onSubmitted: _handleSubmit,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty) ...[
                  IconButton(
                    key: const Key('search_clear_button'),
                    onPressed: _handleClearSearch,
                    icon: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14.0,
                        color: Color(0xFF475569),
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28.0,
                      minHeight: 28.0,
                    ),
                  ),
                  Container(
                    width: 1.0,
                    height: 18.0,
                    color: const Color(0xFFCBD5E1),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  ),
                ],
                IconButton(
                  key: const Key('search_mic_button'),
                  onPressed: _handleVoiceSearch,
                  icon: const Icon(
                    Icons.mic_none_rounded,
                    size: 20.0,
                    color: Color(0xFF0F172A),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32.0,
                    minHeight: 32.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Initial View with Recent Searches & Popular Tags when query is empty.
  Widget _buildEmptyQueryView(BuildContext context, bool isDark) {
    final recentSearches = ref.watch(recentSearchesProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // 1. Recent Searches
          if (recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT SEARCHES',
                  style: TextStyle(
                    fontSize: context.sp(12.0),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
                    letterSpacing: 0.8,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(recentSearchesProvider.notifier).clearAll(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: context.sp(12.5),
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF34D399) : AppColors.primary,
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: recentSearches.map((item) {
                return AppChip(
                  label: item,
                  variant: ChipVariant.input,
                  icon: Icons.history_rounded,
                  onTap: () => _selectAndSubmitSearch(item),
                  onDeleted: () {
                    ref.read(recentSearchesProvider.notifier).removeSearch(item);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24.0),
          ],

          // 2. Popular Categories / Keyword Tags
          Text(
            'POPULAR SEARCHES',
            style: TextStyle(
              fontSize: context.sp(12.0),
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
              letterSpacing: 0.8,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
          const SizedBox(height: 10.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              'Fresh Apples',
              'Bananas',
              'Potatoes',
              'Tomatoes',
              'Mangoes',
              'Onions',
              'Fresh Fruits',
              'Fresh Vegetables',
            ].map((tag) {
              return AppChip(
                label: tag,
                variant: ChipVariant.action,
                onTap: () => _selectAndSubmitSearch(tag),
              );
            }).toList(),
          ),
        ],
      ),
    ),
  );
}

  /// Screen 17: Live Suggestions View matching 17_Search.png.
  Widget _buildSuggestionsView(
    BuildContext context,
    bool isDark,
    Map<String, double> cartMap,
  ) {
    final suggestions = ref.watch(searchSuggestionsProvider(_currentQuery));
    final productMatches = suggestions.productSuggestions;
    final queryMatches = suggestions.querySuggestions;

    if (productMatches.isEmpty && queryMatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No suggestions match "$_currentQuery".\nPress Enter to search.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.sp(14.0),
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        // 1. Product Matches Section (Search Selection Only)
        if (productMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'PRODUCT MATCHES',
              style: TextStyle(
                fontSize: context.sp(12.0),
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
                letterSpacing: 0.8,
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
          ),
          Divider(
            height: 1.0,
            color: isDark ? AppColors.cardBorderDark : const Color(0xFFF1F5F9),
          ),
          ...productMatches.map((product) {
            return SearchSuggestionRow(
              product: product,
              searchQuery: _currentQuery,
              onTap: () => _selectAndSubmitSearch(product.name),
            );
          }),
        ],

        // 2. Search Suggestions Section
        if (queryMatches.isNotEmpty) ...[
          if (productMatches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Divider(
                height: 1.0,
                color: isDark ? AppColors.cardBorderDark : const Color(0xFFF1F5F9),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'SEARCH SUGGESTIONS',
              style: TextStyle(
                fontSize: context.sp(12.0),
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
                letterSpacing: 0.8,
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
          ),
          ...queryMatches.map((queryText) {
            return SearchQuerySuggestionItem(
              query: queryText,
              onTap: () => _selectAndSubmitSearch(queryText),
            );
          }),
        ],
      ],
    );
  }

  /// Screen 18: Search Results Grid matching 18_Search_Results.png.
  Widget _buildSearchResultsGrid({
    required BuildContext context,
    required bool isDark,
    required List<ProductModel> results,
    required List<dynamic> categories,
    required Map<String, double> cartMap,
    required Set<String> favoritesSet,
  }) {
    final selectedCategory = ref.watch(searchSelectedCategoryProvider);
    final sortOption = ref.watch(searchSortOptionProvider);

    return Column(
      children: [
        // 1. Meta Filter Bar
        SearchFilterBar(
          totalCount: results.length,
          query: _currentQuery,
          categories: categories.cast(),
          selectedCategoryId: selectedCategory,
          sortOption: sortOption,
          onCategorySelected: (catId) {
            ref.read(searchSelectedCategoryProvider.notifier).state = catId;
          },
          onSortSelected: (sort) {
            ref.read(searchSortOptionProvider.notifier).state = sort;
          },
          onFilterTap: _handleFilterTap,
        ),
        const SizedBox(height: 8.0),

        // 2. 2-Column Product Grid
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 14.0,
              mainAxisExtent: context.r(112) + 108.0,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final product = results[index];
              final cartQty = cartMap[product.id] ?? 0;
              final isFav = favoritesSet.contains(product.id);

              return AppProductCard(
                id: product.id,
                name: product.name,
                price: product.price,
                unit: product.unit,
                oldPrice: product.mrp,
                badge: product.resolvedBadge,
                imageUrl: product.imageUrl,
                quantity: cartQty,
                canIncrement: product.quantityRule.canIncrement(cartQty),
                isFavorite: isFav,
                isPurchasable: product.isPurchasable,
                onTap: () => _handleProductTap(product),
                onAddToCart: () => ref.read(cartNotifierProvider.notifier).increment(product.id, rule: product.quantityRule),
                onIncrement: () => ref.read(cartNotifierProvider.notifier).increment(product.id, rule: product.quantityRule),
                onDecrement: () => ref.read(cartNotifierProvider.notifier).decrement(product.id, rule: product.quantityRule),
                onToggleFavorite: () => ref.read(favoritesNotifierProvider.notifier).toggleFavorite(product.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
