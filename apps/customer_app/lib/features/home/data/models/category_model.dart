/// Category data model for Unique Basket Customer App.
class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      displayOrder: (json['displayOrder'] as num? ?? json['display_order'] as num? ?? 0).toInt(),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }
}
