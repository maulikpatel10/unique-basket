import '../datasources/customer_address_remote_data_source.dart';

abstract class CustomerAddressRepository {
  Future<Map<String, dynamic>> getAddresses();
  Future<Map<String, dynamic>> addAddress({
    required String title,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  });
}

class CustomerAddressRepositoryImpl implements CustomerAddressRepository {
  final CustomerAddressRemoteDataSource _remoteDataSource;

  CustomerAddressRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>> getAddresses() {
    return _remoteDataSource.getAddresses();
  }

  @override
  Future<Map<String, dynamic>> addAddress({
    required String title,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return _remoteDataSource.addAddress(
      title: title,
      addressLine: addressLine,
      city: city,
      state: state,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );
  }
}
