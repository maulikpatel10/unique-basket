import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/services/startup_state_resolver.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSecureStorageService implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    _data['access_token'] = accessToken;
    if (refreshToken != null) _data['refresh_token'] = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  @override
  Future<String?> getRefreshToken() async => _data['refresh_token'];

  @override
  Future<void> clearTokens() async {
    _data.remove('access_token');
    _data.remove('refresh_token');
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSecureStorageService secureStorage;

  setUp(() {
    secureStorage = MockSecureStorageService();
  });

  group('StartupStateResolver Tests', () {
    test('1. Resolves onboarding for brand-new user (onboarding incomplete)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.onboarding));
    });

    test('2. Resolves mobileAuthentication when onboarding complete but no token', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.mobileAuthentication));
    });

    test('3. Resolves profileSetup when authenticated with token but profile incomplete', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      await secureStorage.saveTokens(accessToken: 'mock_jwt_token');

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.profileSetup));
    });

    test('4. Resolves addressSetup when profile complete but address incomplete', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      await secureStorage.saveTokens(accessToken: 'mock_jwt_token');

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.addressSetup));
    });

    test('5. Resolves home when all steps completed', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
        AppConstants.keyAddressCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      await secureStorage.saveTokens(accessToken: 'mock_jwt_token');

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.home));
    });
  });
}
