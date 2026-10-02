/// Model representing a supported delivery pincode fetched from backend.
class SupportedPincodeModel {
  final String id;
  final String pincode;
  final String city;
  final String state;
  final bool isActive;

  const SupportedPincodeModel({
    required this.id,
    required this.pincode,
    required this.city,
    required this.state,
    required this.isActive,
  });

  factory SupportedPincodeModel.fromJson(Map<String, dynamic> json) {
    return SupportedPincodeModel(
      id: json['id']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      city: json['city']?.toString() ?? 'Rajkot',
      state: json['state']?.toString() ?? 'Gujarat',
      isActive: json['isActive'] == true || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pincode': pincode,
        'city': city,
        'state': state,
        'isActive': isActive,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportedPincodeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pincode == other.pincode &&
          city == other.city &&
          state == other.state &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      pincode.hashCode ^
      city.hashCode ^
      state.hashCode ^
      isActive.hashCode;
}
