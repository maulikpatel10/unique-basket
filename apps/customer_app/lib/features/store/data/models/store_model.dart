/// Store data model for Unique Basket Customer App.
///
/// Maps directly to the backend PostgreSQL `Store` table and nearby store resolution payloads.
class StoreModel {
  final String id;
  final String storeId;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final double deliveryRadiusKm;
  final String phone;
  final String? email;
  final String openingTime;
  final String closingTime;
  final bool isActive;
  final double? distanceKm;
  final bool isEligible;

  const StoreModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.deliveryRadiusKm = 10.0,
    required this.phone,
    this.email,
    required this.openingTime,
    required this.closingTime,
    this.isActive = true,
    this.distanceKm,
    this.isEligible = false,
  });

  StoreModel copyWith({
    String? id,
    String? storeId,
    String? name,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    double? deliveryRadiusKm,
    String? phone,
    String? email,
    String? openingTime,
    String? closingTime,
    bool? isActive,
    double? distanceKm,
    bool? isEligible,
  }) {
    return StoreModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      isActive: isActive ?? this.isActive,
      distanceKm: distanceKm ?? this.distanceKm,
      isEligible: isEligible ?? this.isEligible,
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

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? json['store_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      deliveryRadiusKm: _parseDouble(
          json['deliveryRadiusKm'] ?? json['delivery_radius_km'], 10.0),
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      openingTime: json['openingTime'] as String? ??
          json['opening_time'] as String? ??
          '08:00',
      closingTime: json['closingTime'] as String? ??
          json['closing_time'] as String? ??
          '22:00',
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      distanceKm: _parseOptionalDouble(
          json['distanceKm'] ?? json['distance_km']),
      isEligible:
          json['isEligible'] as bool? ?? json['is_eligible'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'deliveryRadiusKm': deliveryRadiusKm,
      'phone': phone,
      'email': email,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'isActive': isActive,
      'distanceKm': distanceKm,
      'isEligible': isEligible,
    };
  }
}
