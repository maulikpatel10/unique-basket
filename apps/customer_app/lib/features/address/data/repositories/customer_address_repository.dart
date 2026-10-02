import '../models/supported_pincode_model.dart';
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
  Future<Map<String, dynamic>> updateAddress({
    required String id,
    String? title,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  });
  Future<Map<String, dynamic>> setDefaultAddress(String id);
  Future<Map<String, dynamic>> deleteAddress(String id);
  Future<List<SupportedPincodeModel>> getSupportedPincodes();
  Future<Map<String, dynamic>> checkPincodeServiceability(String pincode);
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

  @override
  Future<Map<String, dynamic>> updateAddress({
    required String id,
    String? title,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return _remoteDataSource.updateAddress(
      id: id,
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

  @override
  Future<Map<String, dynamic>> setDefaultAddress(String id) {
    return _remoteDataSource.setDefaultAddress(id);
  }

  @override
  Future<Map<String, dynamic>> deleteAddress(String id) {
    return _remoteDataSource.deleteAddress(id);
  }

  @override
  Future<List<SupportedPincodeModel>> getSupportedPincodes() {
    return _remoteDataSource.getSupportedPincodes();
  }

  @override
  Future<Map<String, dynamic>> checkPincodeServiceability(String pincode) {
    return _remoteDataSource.checkPincodeServiceability(pincode);
  }
}
