/// Product data model for Unique Basket Customer App.
class ProductModel {
  final String id;
  final String categoryId;
  final String? categoryName;
  final String name;
  final String? description;
  final double price;
  final double? mrp;
  final String unit;
  final String? imageUrl;
  final String? badge;
  final double stockQuantity;
  final double? lowStockThreshold;
  final bool isAvailable;
  final bool isFavorite;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    required this.price,
    this.mrp,
    required this.unit,
    this.imageUrl,
    this.badge,
    this.stockQuantity = 10.0,
    this.lowStockThreshold,
    this.isAvailable = true,
    this.isFavorite = false,
    this.isActive = true,
  });

  /// True if the product is active, available, and has stock > 0.
  bool get isPurchasable => isActive && isAvailable && stockQuantity > 0;

  /// Returns explicit badge or calculates discount badge if MRP > price.
  String? get resolvedBadge {
    if (badge != null && badge!.isNotEmpty) return badge;
    if (mrp != null && mrp! > price && mrp! > 0) {
      final discount = (((mrp! - price) / mrp!) * 100).round();
      if (discount >= 5) {
        return '$discount% OFF';
      }
    }
    return null;
  }

  ProductModel copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? name,
    String? description,
    double? price,
    double? mrp,
    String? unit,
    String? imageUrl,
    String? badge,
    double? stockQuantity,
    double? lowStockThreshold,
    bool? isAvailable,
    bool? isFavorite,
    bool? isActive,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      badge: badge ?? this.badge,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isAvailable: isAvailable ?? this.isAvailable,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
    );
  }

  static double _parseDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? _parseOptionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? json['category_id'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? json['category_name'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: _parseDouble(json['price']),
      mrp: _parseOptionalDouble(json['mrp']),
      unit: json['unit'] as String? ?? '1 kg',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      badge: json['badge'] as String?,
      stockQuantity: _parseDouble(
          json['stockQuantity'] ?? json['stock_quantity']),
      lowStockThreshold: _parseOptionalDouble(
          json['lowStockThreshold'] ?? json['low_stock_threshold']),
      isAvailable: json['isAvailable'] as bool? ?? json['is_available'] as bool? ?? true,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'name': name,
      'description': description,
      'price': price,
      'mrp': mrp,
      'unit': unit,
      'imageUrl': imageUrl,
      'badge': badge,
      'stockQuantity': stockQuantity,
      'lowStockThreshold': lowStockThreshold,
      'isAvailable': isAvailable,
      'isFavorite': isFavorite,
      'isActive': isActive,
    };
  }
}
