class DeliverySettingsModel {
  /// Fallbacks used only when the backend omits a value (D-009). The backend
  /// remains authoritative for the fees charged on an order.
  static const double defaultDeliveryFee = 30.0;
  static const double defaultFreeDeliveryThreshold = 200.0;
  static const double defaultMinimumOrderAmount = 199.0;

  final double deliveryFee;
  final bool deliveryEnabled;
  final double freeDeliveryThreshold;
  final double minimumOrderAmount;

  const DeliverySettingsModel({
    this.deliveryFee = defaultDeliveryFee,
    this.deliveryEnabled = true,
    this.freeDeliveryThreshold = defaultFreeDeliveryThreshold,
    this.minimumOrderAmount = defaultMinimumOrderAmount,
  });

  factory DeliverySettingsModel.fromJson(Map<String, dynamic> json) {
    return DeliverySettingsModel(
      deliveryFee: _parseDouble(json['deliveryFee'], defaultDeliveryFee),
      deliveryEnabled: json['deliveryEnabled'] is bool
          ? json['deliveryEnabled'] as bool
          : true,
      freeDeliveryThreshold: _parseDouble(json['freeDeliveryThreshold'], defaultFreeDeliveryThreshold),
      minimumOrderAmount: _parseDouble(json['minimumOrderAmount'], defaultMinimumOrderAmount),
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
