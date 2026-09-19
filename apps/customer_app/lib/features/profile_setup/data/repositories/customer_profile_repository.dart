import '../datasources/customer_profile_remote_data_source.dart';

abstract class CustomerProfileRepository {
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    DateTime? dob,
  });
}

class CustomerProfileRepositoryImpl implements CustomerProfileRepository {
  final CustomerProfileRemoteDataSource _remoteDataSource;

  CustomerProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>> getProfile() {
    return _remoteDataSource.getProfile();
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    DateTime? dob,
  }) {
    return _remoteDataSource.updateProfile(name: name, email: email, dob: dob);
  }
}
