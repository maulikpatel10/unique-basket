import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/authentication/data/datasources/session_revocation_remote_data_source.dart';
import 'package:customer_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:customer_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P1-08: logout revokes the backend refresh session (best effort) before clearing local state.
class _MemorySecureStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    _data[AppConstants.keyAccessToken] = accessToken;
    if (refreshToken != null) _data[AppConstants.keyRefreshToken] = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _data[AppConstants.keyAccessToken];

  @override
  Future<String?> getRefreshToken() async => _data[AppConstants.keyRefreshToken];

  @override
  Future<void> clearTokens() async {
    _data.remove(AppConstants.keyAccessToken);
    _data.remove(AppConstants.keyRefreshToken);
  }

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clearAll() async => _data.clear();
}

class _NoopAuthRepository implements AuthRepository {
  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async => {};

  @override
  Future<String?> refreshToken(String refreshToken) async => null;
}

class _FakeRevocation implements SessionRevocationRemoteDataSource {
  final bool shouldFail;
  final List<String> revoked = [];
  _FakeRevocation({this.shouldFail = false});

  @override
  Future<void> revokeSession(String refreshToken) async {
    revoked.add(refreshToken);
    if (shouldFail) throw Exception('offline');
  }
}

void main() {
  setUp(() {
    AppConfig.initialize(appName: 'Unique Basket', environment: Environment.development);
  });

  Future<(ProviderContainer, _MemorySecureStorage)> buildContainer(_FakeRevocation revocation) async {
    SharedPreferences.setMockInitialValues({});
    final localStorage = LocalStorageService(await SharedPreferences.getInstance());
    final secureStorage = _MemorySecureStorage();
    await secureStorage.saveTokens(accessToken: 'access_a', refreshToken: 'refresh_a');

    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        secureStorageProvider.overrideWithValue(secureStorage),
        authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
        sessionRevocationDataSourceProvider.overrideWithValue(revocation),
      ],
    );
    addTearDown(container.dispose);
    return (container, secureStorage);
  }

  test('logout revokes the refresh session on the backend, then clears tokens', () async {
    final revocation = _FakeRevocation();
    final (container, secureStorage) = await buildContainer(revocation);

    await container.read(authNotifierProvider.notifier).logout();

    expect(revocation.revoked, ['refresh_a']);
    expect(await secureStorage.getAccessToken(), isNull);
    expect(await secureStorage.getRefreshToken(), isNull);
  });

  test('logout still clears local session when the backend call fails', () async {
    final revocation = _FakeRevocation(shouldFail: true);
    final (container, secureStorage) = await buildContainer(revocation);

    await container.read(authNotifierProvider.notifier).logout();

    expect(revocation.revoked, ['refresh_a']);
    expect(await secureStorage.getAccessToken(), isNull);
    expect(await secureStorage.getRefreshToken(), isNull);
  });
}
