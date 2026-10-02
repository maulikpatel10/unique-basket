class DeliverySettingsModel {
  final double deliveryFee;
  final bool deliveryEnabled;
  final double freeDeliveryThreshold;
  final double minimumOrderAmount;

  const DeliverySettingsModel({
    this.deliveryFee = 30.0,
    this.deliveryEnabled = true,
    this.freeDeliveryThreshold = 499.0,
    this.minimumOrderAmount = 199.0,
  });

  factory DeliverySettingsModel.fromJson(Map<String, dynamic> json) {
    return DeliverySettingsModel(
      deliveryFee: _parseDouble(json['deliveryFee'], 30.0),
      deliveryEnabled: json['deliveryEnabled'] is bool
          ? json['deliveryEnabled'] as bool
          : true,
      freeDeliveryThreshold: _parseDouble(json['freeDeliveryThreshold'], 499.0),
      minimumOrderAmount: _parseDouble(json['minimumOrderAmount'], 199.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryFee': deliveryFee,
      'deliveryEnabled': deliveryEnabled,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'minimumOrderAmount': minimumOrderAmount,
    };
  }

  static double _parseDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
