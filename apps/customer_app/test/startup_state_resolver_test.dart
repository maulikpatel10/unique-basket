import 'dart:convert';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/errors/app_exception.dart';
import 'package:customer_app/core/services/startup_state_resolver.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSecureStorageService implements SecureStorageService {
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

class MockAuthRepository implements AuthRepository {
  int refreshTokenCallCount = 0;
  String? Function(String refreshToken)? onRefreshToken;

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async => {};

  @override
  Future<String?> refreshToken(String refreshToken) async {
    refreshTokenCallCount++;
    if (onRefreshToken != null) {
      return onRefreshToken!(refreshToken);
    }
    return null;
  }
}

String createMockJwt({required Duration validFor}) {
  final exp = (DateTime.now().add(validFor).millisecondsSinceEpoch ~/ 1000);
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}))).replaceAll('=', '');
  final payload = base64Url.encode(utf8.encode(jsonEncode({'id': 'u1', 'exp': exp}))).replaceAll('=', '');
  return '$header.$payload.mock_signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSecureStorageService secureStorage;
  late MockAuthRepository authRepository;

  setUp(() {
    secureStorage = MockSecureStorageService();
    authRepository = MockAuthRepository();
  });

  group('StartupStateResolver Phase 1 Lifecycle Tests', () {
    test('Test 1: Onboarding incomplete + no tokens -> Onboarding', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.onboarding));
      expect(authRepository.refreshTokenCallCount, equals(0));
    });

    test('Test 2: Onboarding complete + no access token -> Mobile Number', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.mobileAuthentication));
      expect(authRepository.refreshTokenCallCount, equals(0));
    });

    test('Test 3: Onboarding complete + valid access token -> Existing local profile/address startup logic', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
        AppConstants.keyAddressCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final validToken = createMockJwt(validFor: const Duration(minutes: 10));
      await secureStorage.saveTokens(accessToken: validToken);

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.home));
      expect(authRepository.refreshTokenCallCount, equals(0)); // Must NOT call refresh
    });

    test('Test 4: Onboarding complete + expired access token + valid refresh token -> refresh called exactly once -> new access token stored -> existing startup logic continues', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
        AppConstants.keyAddressCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final expiredToken = createMockJwt(validFor: const Duration(minutes: -5));
      final newAccessToken = createMockJwt(validFor: const Duration(minutes: 15));
      const refreshToken = 'valid_refresh_token_abc';

      await secureStorage.saveTokens(
        accessToken: expiredToken,
        refreshToken: refreshToken,
      );

      authRepository.onRefreshToken = (rToken) {
        expect(rToken, equals(refreshToken));
        return newAccessToken;
      };

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.home));
      expect(authRepository.refreshTokenCallCount, equals(1));

      // Verify new access token is stored and refresh token is preserved
      final savedAccessToken = await secureStorage.getAccessToken();
      final savedRefreshToken = await secureStorage.getRefreshToken();
      expect(savedAccessToken, equals(newAccessToken));
      expect(savedRefreshToken, equals(refreshToken));
    });

    test('Test 5: Expired access token + invalid refresh token -> access token cleared -> refresh token cleared -> Mobile Number', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
        AppConstants.keyAddressCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final expiredToken = createMockJwt(validFor: const Duration(minutes: -10));
      await secureStorage.saveTokens(
        accessToken: expiredToken,
        refreshToken: 'invalid_or_expired_refresh_token',
      );

      authRepository.onRefreshToken = (rToken) {
        throw const UnauthorizedException(message: 'Invalid refresh token.');
      };

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.mobileAuthentication));
      expect(authRepository.refreshTokenCallCount, equals(1));

      // Verify tokens cleared
      expect(await secureStorage.getAccessToken(), isNull);
      expect(await secureStorage.getRefreshToken(), isNull);
    });

    test('Test 6: Expired access token + missing refresh token -> auth tokens cleared -> Mobile Number', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final expiredToken = createMockJwt(validFor: const Duration(minutes: -5));
      await secureStorage.saveTokens(accessToken: expiredToken);

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.mobileAuthentication));
      expect(authRepository.refreshTokenCallCount, equals(0)); // No refresh token -> no refresh call

      expect(await secureStorage.getAccessToken(), isNull);
      expect(await secureStorage.getRefreshToken(), isNull);
    });

    test('Test 7: Expired access token + refresh succeeds but response has no usable token -> auth tokens cleared -> Mobile Number', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final expiredToken = createMockJwt(validFor: const Duration(minutes: -5));
      await secureStorage.saveTokens(
        accessToken: expiredToken,
        refreshToken: 'some_refresh_token',
      );

      authRepository.onRefreshToken = (rToken) {
        return null; // Empty / unusable response
      };

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.mobileAuthentication));
      expect(authRepository.refreshTokenCallCount, equals(1));

      expect(await secureStorage.getAccessToken(), isNull);
      expect(await secureStorage.getRefreshToken(), isNull);
    });

    test('Test 8: Valid access token -> refresh endpoint must NOT be called', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final validToken = createMockJwt(validFor: const Duration(minutes: 12));
      await secureStorage.saveTokens(
        accessToken: validToken,
        refreshToken: 'refresh_token_123',
      );

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      await resolver.resolve();
      expect(authRepository.refreshTokenCallCount, equals(0));
    });

    test('Test 9: Valid access token + incomplete profile -> Profile Setup', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: false,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final validToken = createMockJwt(validFor: const Duration(minutes: 10));
      await secureStorage.saveTokens(accessToken: validToken);

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.profileSetup));
    });

    test('Test 10: Valid/refreshed access token + complete profile + no address -> First-Time Address', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
        AppConstants.keyAddressCompleted: false,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final validToken = createMockJwt(validFor: const Duration(minutes: 10));
      await secureStorage.saveTokens(accessToken: validToken);

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.addressSetup));
    });

    test('Test 11: Valid/refreshed access token + complete profile + address -> Home', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
        AppConstants.keyAddressCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final validToken = createMockJwt(validFor: const Duration(minutes: 10));
      await secureStorage.saveTokens(accessToken: validToken);

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.home));
    });

    test('Edge Case: Malformed access token -> treated as expired -> attempts refresh', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
        AppConstants.keyAddressCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      const malformedToken = 'malformed.jwt.token';
      final newAccessToken = createMockJwt(validFor: const Duration(minutes: 15));
      const refreshToken = 'valid_refresh_token';

      await secureStorage.saveTokens(
        accessToken: malformedToken,
        refreshToken: refreshToken,
      );

      authRepository.onRefreshToken = (rToken) => newAccessToken;

      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepository,
      );

      final destination = await resolver.resolve();
      expect(destination, equals(StartupDestination.home));
      expect(authRepository.refreshTokenCallCount, equals(1));
    });
  });
}
