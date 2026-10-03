/// Model representing an item in the customer's cart.
class CartItemModel {
  final String id;
  final String productId;
  final String? productName;
  final String? unit;
  final double price;
  final double? mrp;
  final double quantity;
  final double? minQuantity;
  final double? maxQuantity;
  final double? quantityStep;
  final double totalPrice;

  const CartItemModel({
    required this.id,
    required this.productId,
    this.productName,
    this.unit,
    required this.price,
    this.mrp,
    required this.quantity,
    required this.totalPrice,
    this.minQuantity,
    this.maxQuantity,
    this.quantityStep,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final qtyNum = json['quantity'];
    // Decimal quantities are preserved (P1-03): never truncate to an int.
    final quantity = qtyNum is num ? qtyNum.toDouble() : (double.tryParse(qtyNum?.toString() ?? '1') ?? 1.0);
    
    final priceNum = json['price'];
    final price = priceNum is num ? priceNum.toDouble() : (double.tryParse(priceNum?.toString() ?? '0.0') ?? 0.0);

    final mrpNum = json['mrp'];
    final mrp = mrpNum != null ? (mrpNum is num ? mrpNum.toDouble() : double.tryParse(mrpNum.toString())) : null;

    final totalNum = json['totalPrice'];
    final totalPrice = totalNum is num ? totalNum.toDouble() : (price * quantity);

    return CartItemModel(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String?,
      unit: json['unit'] as String?,
      price: price,
      mrp: mrp,
      quantity: quantity,
      totalPrice: totalPrice,
      minQuantity: _optionalDouble(json['minQuantity']),
      maxQuantity: _optionalDouble(json['maxQuantity']),
      quantityStep: _optionalDouble(json['quantityStep']),
    );
  }

  static double? _optionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'unit': unit,
      'price': price,
      'mrp': mrp,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'quantityStep': quantityStep,
    };
  }

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? unit,
    double? price,
    double? mrp,
    double? quantity,
    double? totalPrice,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      minQuantity: minQuantity,
      maxQuantity: maxQuantity,
      quantityStep: quantityStep,
    );
  }
}
