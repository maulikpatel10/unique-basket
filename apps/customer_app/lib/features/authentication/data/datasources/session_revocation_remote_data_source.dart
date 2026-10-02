import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

/// Revokes the server-side refresh session on logout (backend P1-08).
class SessionRevocationRemoteDataSource {
  final ApiClient _apiClient;

  SessionRevocationRemoteDataSource(this._apiClient);

  Future<void> revokeSession(String refreshToken) async {
    await _apiClient.post(
      ApiEndpoints.logout,
      data: {'refreshToken': refreshToken},
    );
  }
}
