import '../datasources/auth_remote_data_source.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phoneNumber);
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp);
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
}
