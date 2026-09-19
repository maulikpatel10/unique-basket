/// Promotional Hero Banner model for Unique Basket Customer App.
class BannerModel {
  final String id;
  final String tag;
  final String title;
  final String ctaText;
  final String? imageUrl;
  final String? deepLink;
  final int displayOrder;
  final bool isActive;

  const BannerModel({
    required this.id,
    this.tag = 'Fresh Harvest',
    required this.title,
    this.ctaText = 'Shop Now',
    this.imageUrl,
    this.deepLink,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String?;
    final title = (rawTitle != null && rawTitle.trim().isNotEmpty)
        ? rawTitle.trim()
        : 'Fresh Produce\nSpecial Offer';

    return BannerModel(
      id: json['id'] as String? ?? '',
      tag: json['tag'] as String? ?? 'Fresh Harvest',
      title: title,
      ctaText: json['ctaText'] as String? ?? json['cta_text'] as String? ?? 'Shop Now',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      deepLink: json['deepLink'] as String? ?? json['deep_link'] as String?,
      displayOrder: (json['displayOrder'] as num? ?? json['display_order'] as num? ?? 0).toInt(),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag': tag,
      'title': title,
      'ctaText': ctaText,
      'imageUrl': imageUrl,
      'deepLink': deepLink,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }
}
