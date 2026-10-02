import 'dart:convert';
import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/errors/app_exception.dart';
import 'package:customer_app/core/network/auth_interceptor.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/services/startup_state_resolver.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/address/data/repositories/customer_address_repository.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:customer_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:customer_app/features/authentication/presentation/screens/verify_otp_screen.dart';
import 'package:customer_app/features/checkout/presentation/providers/order_provider.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:customer_app/features/profile_setup/data/repositories/customer_profile_repository.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/features/search/presentation/providers/search_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTestSecureStorageService implements SecureStorageService {
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

class MockMultiAccountAuthRepository implements AuthRepository {
  String? lastVerifiedPhone;

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    lastVerifiedPhone = phoneNumber;
    final isUserA = phoneNumber.contains('9876543210');
    return {
      'success': true,
      'data': {
        'user': {
          'id': isUserA ? 'user_a_123' : 'user_b_456',
          'phone': phoneNumber,
          'name': isUserA ? 'User A Name' : null,
        },
        'isNewUser': !isUserA,
        'token': isUserA ? 'jwt_token_user_a' : 'jwt_token_user_b',
        'refreshToken': isUserA ? 'refresh_user_a' : 'refresh_user_b',
      },
    };
  }

  @override
  Future<String?> refreshToken(String refreshToken) async {
    return 'new_token';
  }
}

class MockMultiAccountProfileRepository implements CustomerProfileRepository {
  @override
  Future<Map<String, dynamic>> getProfile() async {
    return {
      'success': true,
      'data': {'user': {}},
    };
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    DateTime? dob,
    String? gender,
  }) async {
    return {'success': true};
  }
}

class MockMultiAccountAddressRepository implements CustomerAddressRepository {
  @override
  Future<Map<String, dynamic>> getAddresses() async {
    return {
      'success': true,
      'data': {'addresses': []},
    };
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
    return {'success': true};
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
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> setDefaultAddress(String id) async {
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> deleteAddress(String id) async {
    return {'success': true};
  }

  @override
  Future<List<SupportedPincodeModel>> getSupportedPincodes() async => const [];

  @override
  Future<Map<String, dynamic>> checkPincodeServiceability(String pincode) async => {
        'isServiceable': true,
        'pincode': pincode,
        'city': 'Rajkot',
        'state': 'Gujarat',
      };
}

String _createMockJwt({required Duration validFor}) {
  final exp = (DateTime.now().add(validFor).millisecondsSinceEpoch ~/ 1000);
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}))).replaceAll('=', '');
  final payload = base64Url.encode(utf8.encode(jsonEncode({'id': 'u1', 'exp': exp}))).replaceAll('=', '');
  return '$header.$payload.mock_signature';
}

class FakeHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  FakeHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponseBody(Map<String, dynamic> data, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    AppConfig.initialize(
      appName: 'Unique Basket',
      environment: Environment.development,
    );
  });

  group('Part 1 — Local Storage Session Cleanup Tests', () {
    test('clearUserSessionData() wipes all user keys and preserves onboarding completion', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      // Populate User A data
      await localStorage.setJson(AppConstants.keyUserData, {'name': 'User A', 'phone': '+919876543210'});
      await localStorage.setString(AppConstants.keyUserDob, '1995-05-20');
      await localStorage.setJson(AppConstants.keyUserAddress, {'title': 'Home', 'addressLine': '123 Main St'});
      await localStorage.setBool(AppConstants.keyProfileCompleted, true);
      await localStorage.setBool(AppConstants.keyAddressCompleted, true);
      await localStorage.setStringList(AppConstants.keyCustomerRecentSearches, ['Apples', 'Milk']);
      await localStorage.setBool(AppConstants.keyOnboardingCompleted, true);

      // Verify populated
      expect(localStorage.getJson(AppConstants.keyUserData), isNotNull);
      expect(localStorage.getString(AppConstants.keyUserDob), equals('1995-05-20'));
      expect(localStorage.getJson(AppConstants.keyUserAddress), isNotNull);
      expect(localStorage.getBool(AppConstants.keyProfileCompleted), isTrue);
      expect(localStorage.getBool(AppConstants.keyAddressCompleted), isTrue);
      expect(localStorage.getStringList(AppConstants.keyCustomerRecentSearches), isNotEmpty);
      expect(localStorage.getBool(AppConstants.keyOnboardingCompleted), isTrue);

      // Execute session cleanup
      await localStorage.clearUserSessionData();

      // Assert all user keys are purged
      expect(localStorage.getJson(AppConstants.keyUserData), isNull);
      expect(localStorage.getString(AppConstants.keyUserDob), isNull);
      expect(localStorage.getJson(AppConstants.keyUserAddress), isNull);
      expect(localStorage.getBool(AppConstants.keyProfileCompleted), isNull);
      expect(localStorage.getBool(AppConstants.keyAddressCompleted), isNull);
      expect(localStorage.getStringList(AppConstants.keyCustomerRecentSearches), isNull);

      // Assert device-level onboarding is strictly preserved
      expect(localStorage.getBool(AppConstants.keyOnboardingCompleted), isTrue);
    });
  });

  group('Part 2 — AuthNotifier Logout & In-Memory Provider Teardown Tests', () {
    test('logout() clears tokens, local storage user cache, and resets in-memory providers', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final secureStorage = MockTestSecureStorageService();
      final authRepo = MockMultiAccountAuthRepository();

      await secureStorage.saveTokens(accessToken: 'user_a_token', refreshToken: 'user_a_refresh');
      await localStorage.setJson(AppConstants.keyUserData, {'name': 'User A'});
      await localStorage.setBool(AppConstants.keyProfileCompleted, true);
      await localStorage.setBool(AppConstants.keyOnboardingCompleted, true);

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );

      // Populate in-memory state for User A
      container.read(cartNotifierProvider.notifier).increment('prod_1');
      container.read(favoritesNotifierProvider.notifier).toggleFavorite('prod_fav_1');
      container.read(recentSearchesProvider.notifier).addSearch('Fresh Mangoes');

      expect(container.read(cartNotifierProvider), isNotEmpty);
      expect(container.read(favoritesNotifierProvider), isNotEmpty);
      expect(container.read(recentSearchesProvider), contains('Fresh Mangoes'));

      // Perform Logout
      await container.read(authNotifierProvider.notifier).logout();

      // Assert Secure Tokens removed
      expect(await secureStorage.getAccessToken(), isNull);
      expect(await secureStorage.getRefreshToken(), isNull);

      // Assert Local Storage purged
      expect(localStorage.getJson(AppConstants.keyUserData), isNull);
      expect(localStorage.getBool(AppConstants.keyProfileCompleted), isNull);
      expect(localStorage.getBool(AppConstants.keyOnboardingCompleted), isTrue);

      // Assert In-Memory Providers reset
      expect(container.read(cartNotifierProvider), isEmpty);
      expect(container.read(favoritesNotifierProvider), isEmpty);
      expect(container.read(recentSearchesProvider), isEmpty);

      container.dispose();
    });
  });

  group('Part 3 — User A Logout → User B Login (Complete Isolation Test)', () {
    testWidgets('User A logs out -> User B logs in -> User B does NOT inherit User A state',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final secureStorage = MockTestSecureStorageService();
      final authRepo = MockMultiAccountAuthRepository();
      final profileRepo = MockMultiAccountProfileRepository();
      final addressRepo = MockMultiAccountAddressRepository();

      // Simulate User A having established session
      await secureStorage.saveTokens(accessToken: 'token_user_a', refreshToken: 'refresh_user_a');
      await localStorage.setJson(AppConstants.keyUserData, {'name': 'User A', 'phone': '+919876543210'});
      await localStorage.setJson(AppConstants.keyUserAddress, {'title': 'Home', 'addressLine': 'User A Flat 101'});
      await localStorage.setBool(AppConstants.keyProfileCompleted, true);
      await localStorage.setBool(AppConstants.keyAddressCompleted, true);
      await localStorage.setBool(AppConstants.keyOnboardingCompleted, true);

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          authRepositoryProvider.overrideWithValue(authRepo),
          customerProfileRepositoryProvider.overrideWithValue(profileRepo),
          customerAddressRepositoryProvider.overrideWithValue(addressRepo),
        ],
      );

      // User A state in providers
      container.read(cartNotifierProvider.notifier).increment('apple_123');
      container.read(favoritesNotifierProvider.notifier).toggleFavorite('apple_123');

      // User A logs out
      await container.read(authNotifierProvider.notifier).logout();

      // Verify User A local cache is gone
      expect(localStorage.getJson(AppConstants.keyUserData), isNull);
      expect(localStorage.getJson(AppConstants.keyUserAddress), isNull);
      expect(localStorage.getBool(AppConstants.keyProfileCompleted), isNull);
      expect(localStorage.getBool(AppConstants.keyAddressCompleted), isNull);
      expect(localStorage.getBool(AppConstants.keyOnboardingCompleted), isTrue);

      // User B enters OTP
      Map<String, dynamic>? verifiedPayload;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: VerifyOtpScreen(
              phoneNumber: '+919999999999',
              onVerified: (payload) => verifiedPayload = payload,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump(const Duration(milliseconds: 100));

      // Assert User B receives clean fresh session
      expect(verifiedPayload, isNotNull);
      expect(verifiedPayload?['isNewUser'], isTrue);
      expect(verifiedPayload?['destination'], equals(RouteNames.profileSetup));

      // Assert User B has no cart or favorites from User A
      expect(container.read(cartNotifierProvider), isEmpty);
      expect(container.read(favoritesNotifierProvider), isEmpty);

      container.dispose();
    });
  });

  group('Part 4 — StartupStateResolver Account Switch Routing Tests', () {
    test('StartupStateResolver sends User B (new user) to Profile Setup after User A logout', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final secureStorage = MockTestSecureStorageService();
      final authRepo = MockMultiAccountAuthRepository();

      // Device already completed onboarding
      await localStorage.setBool(AppConstants.keyOnboardingCompleted, true);

      // User B has fresh valid token after login
      final validJwt = _createMockJwt(validFor: const Duration(hours: 1));
      await secureStorage.saveTokens(accessToken: validJwt);

      // Since User A's session was cleaned, profile/address completed keys are null
      final resolver = StartupStateResolver(
        localStorage: localStorage,
        secureStorage: secureStorage,
        authRepository: authRepo,
      );

      final destination = await resolver.resolve();

      // Must route to profileSetup, NOT home!
      expect(destination, equals(StartupDestination.profileSetup));

      // Case: User B completes profile only
      await localStorage.setBool(AppConstants.keyProfileCompleted, true);
      final destAfterProfile = await resolver.resolve();
      expect(destAfterProfile, equals(StartupDestination.addressSetup));

      // Case: User B completes address
      await localStorage.setBool(AppConstants.keyAddressCompleted, true);
      final destAfterAddress = await resolver.resolve();
      expect(destAfterAddress, equals(StartupDestination.home));
    });
  });

  group('Part 5 — AuthInterceptor 401 Session Teardown Tests', () {
    test('AuthInterceptor clears local user session cache when refresh token is rejected', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final secureStorage = MockTestSecureStorageService();

      await secureStorage.saveTokens(accessToken: 'expired_tok', refreshToken: 'invalid_refresh');
      await localStorage.setJson(AppConstants.keyUserData, {'name': 'Stale User'});
      await localStorage.setBool(AppConstants.keyProfileCompleted, true);
      await localStorage.setBool(AppConstants.keyOnboardingCompleted, true);

      final tokenDio = Dio(BaseOptions(baseUrl: 'https://api.uniquebasket.com'));
      tokenDio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        return jsonResponseBody({'success': false, 'message': 'Invalid refresh token'}, 401);
      });

      final interceptor = AuthInterceptor(
        secureStorage: secureStorage,
        tokenDio: tokenDio,
        localStorage: localStorage,
      );

      final mainDio = Dio(BaseOptions(baseUrl: 'https://api.uniquebasket.com'));
      mainDio.interceptors.add(interceptor);
      mainDio.httpClientAdapter = FakeHttpClientAdapter((options) async {
        return jsonResponseBody({'success': false, 'message': 'Unauthorized'}, 401);
      });

      try {
        await mainDio.get('/api/v1/customer/profile');
      } catch (_) {}

      // Tokens must be cleared
      expect(await secureStorage.getAccessToken(), isNull);
      // Local user cache must be cleared
      expect(localStorage.getJson(AppConstants.keyUserData), isNull);
      expect(localStorage.getBool(AppConstants.keyProfileCompleted), isNull);
      // Onboarding must be preserved
      expect(localStorage.getBool(AppConstants.keyOnboardingCompleted), isTrue);
    });
  });
}
