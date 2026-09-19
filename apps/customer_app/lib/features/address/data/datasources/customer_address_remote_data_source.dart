import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class CustomerAddressRemoteDataSource {
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

class CustomerAddressRemoteDataSourceImpl implements CustomerAddressRemoteDataSource {
  final ApiClient _apiClient;

  CustomerAddressRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getAddresses() async {
    final response = await _apiClient.get(ApiEndpoints.addresses);
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
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
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.addresses,
      data: {
        'title': title,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (isDefault != null) 'isDefault': isDefault,
      },
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
  }
}
