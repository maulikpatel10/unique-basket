import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

import '../models/supported_pincode_model.dart';

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
  }) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.addresses}/$id',
      data: {
        if (title != null) 'title': title,
        if (addressLine != null) 'addressLine': addressLine,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
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

  @override
  Future<Map<String, dynamic>> setDefaultAddress(String id) async {
    final response = await _apiClient.patch('${ApiEndpoints.addresses}/$id/default');
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> deleteAddress(String id) async {
    final response = await _apiClient.delete('${ApiEndpoints.addresses}/$id');
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
  }

  @override
  Future<List<SupportedPincodeModel>> getSupportedPincodes() async {
    final response = await _apiClient.get(ApiEndpoints.supportedPincodes);
    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response['pincodes'];
      if (data is List) {
        return data
            .map((item) => SupportedPincodeModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> checkPincodeServiceability(String pincode) async {
    final response = await _apiClient.get(
      ApiEndpoints.serviceabilityCheck,
      queryParameters: {'pincode': pincode},
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
  }
}
