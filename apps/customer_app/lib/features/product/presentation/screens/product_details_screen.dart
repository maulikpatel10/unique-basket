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
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_product_card.dart';
import '../../../../shared/widgets/product_quantity_control.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/providers/home_provider.dart';

/// Screen 11 — Product Details (Phase 2 Full UI Implementation).
///
/// Layout hierarchy:
/// - Top action bar (Back, Favorite, Search, Share).
/// - Hero product image showcase with fallback produce styling.
/// - Product information:
///   - Product Name (left-aligned)
///   - Pack / Unit (left-aligned)
///   - Current Price + MRP on same horizontal line (left-aligned)
/// - Collapsible "Product Detail" description section.
/// - Farm / Category origin card navigating to category product listing.
/// - Similar products section reusing canonical [AppProductCard].
/// - Sticky bottom action bar with unit, current price, MRP, and "Add to Cart" CTA.
class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;
  final ProductModel? initialProduct;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  bool _isDetailExpanded = true;

  void _handleBackTap() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      GoRouter.of(context).go(RouteNames.home);
    }
  }

  void _handleSearchTap() {
    try {
      GoRouter.of(context).push(RouteNames.search);
    } catch (_) {
      // Fallback
    }
  }

  void _handleShareTap(ProductModel product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${product.name}"...'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleCategoryTap(ProductModel product) {
    if (product.categoryId.isNotEmpty) {
      GoRouter.of(context).push(
        '${RouteNames.categoryProducts}?categoryId=${product.categoryId}&categoryName=${Uri.encodeComponent(product.categoryName ?? 'Produce')}',
        extra: {
          'categoryId': product.categoryId,
          'categoryName': product.categoryName ?? 'Produce',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve product from initialProduct or from home products provider
    final homeProductsAsync = ref.watch(homeProductsProvider);
    final ProductModel? product = widget.initialProduct ??
        homeProductsAsync.value?.cast<ProductModel?>().firstWhere(
              (p) => p?.id == widget.productId,
              orElse: () => null,
            );

    if (product == null) {
      if (homeProductsAsync.isLoading) {
        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFFAFAFA),
          body: const SafeArea(
            child: Center(child: AppLoading()),
          ),
        );
      }
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Center(
            child: AppEmptyState(
              title: 'Product not found',
              message: 'This product could not be loaded or is unavailable.',
              actionText: 'Go Back',
              onAction: _handleBackTap,
            ),
          ),
        ),
      );
    }

    final cart = ref.watch(cartNotifierProvider);
    final favorites = ref.watch(favoritesNotifierProvider);
    final currentQuantity = cart[product.id] ?? 0;
    final isFavorite = favorites.contains(product.id) || product.isFavorite;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFFAFAFA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: _buildTopActionBar(context, product, isFavorite, isDark),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Product Image
            _buildHeroImage(context, product, isDark),

            // Product Main Information (Left aligned vertical stack)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: context.r(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Product Name
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: context.sp(24),
                      fontWeight: FontWeight.w800,
                      fontFamily: AppTextStyles.fontFamily,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 2. Pack / Unit Subtitle
                  Text(
                    product.unit,
                    style: TextStyle(
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.w500,
                      fontFamily: AppTextStyles.fontFamily,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Current Price + MRP on same horizontal line (Left aligned)
                  _buildPriceAndMrpRow(context, product, isDark),

                  SizedBox(height: context.r(20)),
                  Divider(
                    color: isDark
                        ? AppColors.cardBorderDark
                        : const Color(0xFFF1F5F9),
                    height: 1,
                    thickness: 1,
                  ),
                  SizedBox(height: context.r(16)),

                  // Collapsible Product Detail Section
                  _buildProductDetailSection(context, product, isDark),

                  SizedBox(height: context.r(20)),

                  // Farm / Category Origin Card
                  _buildFarmCategoryCard(context, product, isDark),

                  SizedBox(height: context.r(24)),

                  // Similar Products Section
                  _buildSimilarProductsSection(context, product, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildStickyBottomBar(
        context,
        product,
        currentQuantity,
        isDark,
      ),
    );
  }

  /// Top Floating Action Bar with Back, Favorite, Search, and Share buttons.
  Widget _buildTopActionBar(
    BuildContext context,
    ProductModel product,
    bool isFavorite,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : const Color(0xFFFAFAFA),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          _buildCircleIconButton(
            icon: Icons.arrow_back_rounded,
            color: const Color(0xFF014D40),
            onTap: _handleBackTap,
            isDark: isDark,
          ),

          // Right Action Buttons Row
          Row(
            children: [
              // Favorite Button
              _buildCircleIconButton(
                icon: isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? const Color(0xFF014D40) : const Color(0xFF014D40),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(favoritesNotifierProvider.notifier)
                      .toggleFavorite(product.id);
                },
                isDark: isDark,
              ),
              const SizedBox(width: AppSpacing.sm),

              // Search Button
              _buildCircleIconButton(
                icon: Icons.search_rounded,
                color: const Color(0xFF014D40),
                onTap: _handleSearchTap,
                isDark: isDark,
              ),
              const SizedBox(width: AppSpacing.sm),

              // Share Button
              _buildCircleIconButton(
                icon: Icons.share_outlined,
                color: const Color(0xFF014D40),
                onTap: () => _handleShareTap(product),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.surfaceContainerDark : Colors.white,
            border: Border.all(
              color: isDark
                  ? AppColors.cardBorderDark
                  : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Hero Product Image Showcase.
  Widget _buildHeroImage(
    BuildContext context,
    ProductModel product,
    bool isDark,
  ) {
    final hasImageUrl = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        height: context.r(260),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF1F5F3),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImageUrl
            ? Image.network(
                product.imageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: AppLoading());
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackProduceHero(product, isDark),
              )
            : _buildFallbackProduceHero(product, isDark),
      ),
    );
  }

  Widget _buildFallbackProduceHero(ProductModel product, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF014D40).withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.eco_rounded,
              size: 48,
              color: Color(0xFF014D40),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: AppTextStyles.fontFamily,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  /// Left-aligned Price and MRP Row on the same horizontal line.
  Widget _buildPriceAndMrpRow(
    BuildContext context,
    ProductModel product,
    bool isDark,
  ) {
    final hasMrp = product.mrp != null && product.mrp! > product.price;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Current Selling Price (Left aligned)
        Text(
          CurrencyFormatter.format(product.price),
          style: TextStyle(
            fontSize: context.sp(28),
            fontWeight: FontWeight.w800,
            fontFamily: AppTextStyles.fontFamily,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),

        // MRP with strikethrough (on the same row immediately to the right)
        if (hasMrp) ...[
          const SizedBox(width: 10),
          Text(
            'MRP ${CurrencyFormatter.format(product.mrp)}',
            style: TextStyle(
              fontSize: context.sp(14),
              fontWeight: FontWeight.w500,
              fontFamily: AppTextStyles.fontFamily,
              decoration: TextDecoration.lineThrough,
              decorationColor: const Color(0xFF94A3B8),
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }

  /// Collapsible Product Detail Description.
  Widget _buildProductDetailSection(
    BuildContext context,
    ProductModel product,
    bool isDark,
  ) {
    final descriptionText = product.description?.isNotEmpty == true
        ? product.description!
        : 'Grown in the rich soils of Michoacán, these premium organic products offer an unparalleled creamy texture and rich, authentic flavor. Picked at peak freshness.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with expand/collapse chevron
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isDetailExpanded = !_isDetailExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Product Detail',
                    style: TextStyle(
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTextStyles.fontFamily,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  Icon(
                    _isDetailExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF0F172A),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Collapsible Text Body
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              descriptionText,
              style: TextStyle(
                fontSize: context.sp(14),
                height: 1.5,
                fontFamily: AppTextStyles.fontFamily,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isDetailExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 240),
        ),
      ],
    );
  }

  /// Farm / Category Origin Card.
  Widget _buildFarmCategoryCard(
    BuildContext context,
    ProductModel product,
    bool isDark,
  ) {
    final categoryTitle = product.categoryName?.isNotEmpty == true
        ? product.categoryName!
        : 'Organic Farms';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _handleCategoryTap(product),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF014D40),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryTitle,
                        style: TextStyle(
                          fontSize: context.sp(15),
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTextStyles.fontFamily,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Explore all products',
                        style: TextStyle(
                          fontSize: context.sp(13),
                          fontFamily: AppTextStyles.fontFamily,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Similar Products Section reusing canonical [AppProductCard].
  Widget _buildSimilarProductsSection(
    BuildContext context,
    ProductModel product,
    bool isDark,
  ) {
    final similarProductsAsync = product.categoryId.isNotEmpty
        ? ref.watch(categoryProductsProvider(product.categoryId))
        : ref.watch(homeProductsProvider);

    final allProducts = similarProductsAsync.value ?? [];
    final similarProducts = allProducts
        .where((p) => p.id != product.id && p.isPurchasable)
        .take(4)
        .toList();

    if (similarProducts.isEmpty && !similarProductsAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final cart = ref.watch(cartNotifierProvider);
    final favorites = ref.watch(favoritesNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Similar products',
          style: TextStyle(
            fontSize: context.sp(18),
            fontWeight: FontWeight.w800,
            fontFamily: AppTextStyles.fontFamily,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),

        if (similarProductsAsync.isLoading)
          const Center(child: AppLoading())
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: similarProducts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 14.0,
              mainAxisExtent: context.r(112) + 108.0,
            ),
            itemBuilder: (context, index) {
              final sim = similarProducts[index];
              final simQuantity = cart[sim.id] ?? 0;
              final simIsFav = favorites.contains(sim.id) || sim.isFavorite;

              return AppProductCard(
                id: sim.id,
                name: sim.name,
                price: sim.price,
                unit: sim.unit,
                oldPrice: sim.mrp,
                badge: sim.resolvedBadge,
                imageUrl: sim.imageUrl,
                quantity: simQuantity,
                isFavorite: simIsFav,
                isPurchasable: sim.isPurchasable,
                onAddToCart: () {
                  ref.read(cartNotifierProvider.notifier).increment(sim.id);
                },
                onIncrement: () {
                  ref.read(cartNotifierProvider.notifier).increment(sim.id);
                },
                onDecrement: () {
                  ref.read(cartNotifierProvider.notifier).decrement(sim.id);
                },
                onToggleFavorite: () {
                  ref
                      .read(favoritesNotifierProvider.notifier)
                      .toggleFavorite(sim.id);
                },
                onTap: () {
                  if (!sim.isPurchasable) {
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
                  GoRouter.of(context).push(
                    '${RouteNames.productDetails}?productId=${sim.id}',
                    extra: sim,
                  );
                },
              );
            },
          ),
      ],
    );
  }

  /// Sticky Bottom Action Bar with Unit, Current Price, MRP, and "Add to Cart" CTA.
  Widget _buildStickyBottomBar(
    BuildContext context,
    ProductModel product,
    int currentQuantity,
    bool isDark,
  ) {
    final isPurchasable = product.isPurchasable;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Unit & Price Column
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.unit,
                  style: TextStyle(
                    fontSize: context.sp(12),
                    fontWeight: FontWeight.w500,
                    fontFamily: AppTextStyles.fontFamily,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: TextStyle(
                          fontSize: context.sp(20),
                          fontWeight: FontWeight.w800,
                          fontFamily: AppTextStyles.fontFamily,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF014D40),
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (product.mrp != null && product.mrp! > product.price) ...[
                        const SizedBox(width: 6),
                        Text(
                          CurrencyFormatter.format(product.mrp),
                          style: TextStyle(
                            fontSize: context.sp(13),
                            fontWeight: FontWeight.w500,
                            fontFamily: AppTextStyles.fontFamily,
                            decoration: TextDecoration.lineThrough,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Right: Primary Add to Cart CTA / ProductQuantityControl / Out of Stock
          if (!isPurchasable)
            Container(
              height: 44.0,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.block_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Out of Stock',
                    style: TextStyle(
                      fontSize: context.sp(15),
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (currentQuantity > 0)
            ProductQuantityControl(
              quantity: currentQuantity,
              isDark: isDark,
              height: 44.0,
              expandedWidth: 132.0,
              collapsedWidth: 44.0,
              onAddToCart: () {
                HapticFeedback.lightImpact();
                ref.read(cartNotifierProvider.notifier).increment(product.id);
              },
              onIncrement: () {
                HapticFeedback.lightImpact();
                ref.read(cartNotifierProvider.notifier).increment(product.id);
              },
              onDecrement: () {
                HapticFeedback.lightImpact();
                ref.read(cartNotifierProvider.notifier).decrement(product.id);
              },
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(cartNotifierProvider.notifier)
                      .increment(product.id);
                },
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 44.0,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF014D40),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF014D40)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: context.sp(15),
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTextStyles.fontFamily,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
