import '../datasources/auth_remote_data_source.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phoneNumber);
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp);
  Future<String?> refreshToken(String refreshToken);
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> sendOtp(String phoneNumber) async {
    return _remoteDataSource.sendOtp(phoneNumber);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    return _remoteDataSource.verifyOtp(phoneNumber, otp);
  }

  @override
  Future<String?> refreshToken(String refreshToken) async {
    final response = await _remoteDataSource.refreshToken(refreshToken);
    Map<String, dynamic> data = response;
    if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
      data = response['data'] as Map<String, dynamic>;
    }
    final token = (data['token'] ?? data['accessToken']) as String?;
    return token;
  }
}
