import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class CustomerProfileRemoteDataSource {
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    DateTime? dob,
    String? gender,
  });
}

class CustomerProfileRemoteDataSourceImpl implements CustomerProfileRemoteDataSource {
  final ApiClient _apiClient;

  CustomerProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    DateTime? dob,
    String? gender,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.profile,
      data: {
        'name': name,
        if (email != null) 'email': email,
        if (dob != null)
          'dob': DateTime.utc(dob.year, dob.month, dob.day).toIso8601String(),
        if (gender != null) 'gender': gender,
      },
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
  }
}
