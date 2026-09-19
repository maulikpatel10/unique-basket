import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/app_product_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/models/product_model.dart';

/// Screen 08 (Home) Fresh Arrivals products section.
///
/// Composes the reusable [SectionHeader] and responsive 2-column grid of [AppProductCard]s.
class HomeProductsSection extends StatelessWidget {
  final String title;
  final List<ProductModel> products;
  final Map<String, int> cartQuantities;
  final Set<String> favoriteIds;
  final ValueChanged<ProductModel>? onProductTap;
  final ValueChanged<ProductModel>? onAddToCart;
  final ValueChanged<ProductModel>? onIncrement;
  final ValueChanged<ProductModel>? onDecrement;
  final ValueChanged<ProductModel>? onToggleFavorite;
  final VoidCallback? onViewAllTap;

  const HomeProductsSection({
    super.key,
    this.title = 'Fresh Arrivals',
    required this.products,
    this.cartQuantities = const {},
    this.favoriteIds = const {},
    this.onProductTap,
    this.onAddToCart,
    this.onIncrement,
    this.onDecrement,
    this.onToggleFavorite,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        SectionHeader(
          title: title,
          actionText: onViewAllTap != null ? 'View all' : null,
          onActionTap: onViewAllTap,
        ),

        const SizedBox(height: AppSpacing.sm),

        // 2-Column Product Grid (Responsive layout)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = (constraints.maxWidth - 12.0) / 2;

              return Wrap(
                spacing: 12.0,
                runSpacing: 14.0,
                children: products.map((product) {
                  final quantity = cartQuantities[product.id] ?? 0;
                  final isFav = favoriteIds.contains(product.id);

                  return SizedBox(
                    width: cardWidth,
                    child: AppProductCard(
                      id: product.id,
                      name: product.name,
                      price: product.price,
                      oldPrice: product.mrp,
                      unit: product.unit,
                      badge: product.resolvedBadge,
                      imageUrl: product.imageUrl,
                      isPurchasable: product.isPurchasable,
                      quantity: quantity,
                      isFavorite: isFav,
                      onTap: () => onProductTap?.call(product),
                      onAddToCart: () => onAddToCart?.call(product),
                      onIncrement: () => onIncrement?.call(product),
                      onDecrement: () => onDecrement?.call(product),
                      onToggleFavorite: () => onToggleFavorite?.call(product),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
