import 'cart_item_model.dart';

/// Model representing backend-calculated authoritative cart summary and pricing.
class CartSummaryModel {
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final double freeDeliveryThreshold;

  const CartSummaryModel({
    this.items = const [],
    this.subtotal = 0.0,
    this.deliveryFee = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.freeDeliveryThreshold = 499.0,
  });

  factory CartSummaryModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final List<CartItemModel> parsedItems = [];
    if (itemsJson is List) {
      for (final item in itemsJson) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(CartItemModel.fromJson(item));
        }
      }
    }

    final subtotal = _parseDouble(json['subtotal'], 0.0);
    final deliveryFee = _parseDouble(json['deliveryFee'], 0.0);
    final discount = _parseDouble(json['discount'], 0.0);
    final total = _parseDouble(json['total'], subtotal + deliveryFee - discount);
    final freeDeliveryThreshold = _parseDouble(json['freeDeliveryThreshold'], 499.0);

    return CartSummaryModel(
      items: parsedItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: total,
      freeDeliveryThreshold: freeDeliveryThreshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'freeDeliveryThreshold': freeDeliveryThreshold,
    };
  }

  static double _parseDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
