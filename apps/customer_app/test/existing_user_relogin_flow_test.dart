import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/errors/app_exception.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/address/data/repositories/customer_address_repository.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:customer_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:customer_app/features/authentication/presentation/screens/verify_otp_screen.dart';
import 'package:customer_app/features/profile_setup/data/repositories/customer_profile_repository.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTestAuthRepository implements AuthRepository {
  final bool isNewUser;
  final String? userName;

  MockTestAuthRepository({
    this.isNewUser = false,
    this.userName,
  });

  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    return {
      'success': true,
      'data': {
        'user': {
          'id': 'user_123',
          'phone': phoneNumber,
          if (userName != null) 'name': userName,
        },
        'isNewUser': isNewUser,
        'token': 'mock_jwt_token',
        'refreshToken': 'mock_refresh_token',
      },
    };
  }

  @override
  Future<String?> refreshToken(String refreshToken) async {
    return 'mock_new_access_token';
  }
}

class MockTestProfileRepository implements CustomerProfileRepository {
  final Map<String, dynamic>? profileData;
  final bool throwError;

  MockTestProfileRepository({
    this.profileData,
    this.throwError = false,
  });

  @override
  Future<Map<String, dynamic>> getProfile() async {
    if (throwError) {
      throw const AppException(message: 'Profile service unavailable.');
    }
    return {
      'success': true,
      'data': {
        'user': profileData ?? {},
      },
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

class MockTestAddressRepository implements CustomerAddressRepository {
  final List<Map<String, dynamic>> addresses;
  final bool throwError;

  MockTestAddressRepository({
    this.addresses = const [],
    this.throwError = false,
  });

  @override
  Future<Map<String, dynamic>> getAddresses() async {
    if (throwError) {
      throw const AppException(message: 'Address service unavailable.');
    }
    return {
      'success': true,
      'data': {
        'addresses': addresses,
      },
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

class MockTestSecureStorageService implements SecureStorageService {
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
  Future<void> clearTokens() async => _data.clear();

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clearAll() async => _data.clear();
}

Widget _buildTestApp({
  required LocalStorageService localStorage,
  required AuthRepository authRepo,
  required CustomerProfileRepository profileRepo,
  required CustomerAddressRepository addressRepo,
  ValueChanged<Map<String, dynamic>>? onVerified,
}) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(localStorage),
      secureStorageProvider.overrideWithValue(MockTestSecureStorageService()),
      authRepositoryProvider.overrideWithValue(authRepo),
      customerProfileRepositoryProvider.overrideWithValue(profileRepo),
      customerAddressRepositoryProvider.overrideWithValue(addressRepo),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: VerifyOtpScreen(
        phoneNumber: '+919876543210',
        onVerified: onVerified,
      ),
    ),
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

  group('Post-OTP Existing User Resolution Tests', () {
    testWidgets('Test 1 — New user (isNewUser = true) resolves to Profile Setup',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      Map<String, dynamic>? verifiedPayload;

      await tester.pumpWidget(_buildTestApp(
        localStorage: localStorage,
        authRepo: MockTestAuthRepository(isNewUser: true),
        profileRepo: MockTestProfileRepository(),
        addressRepo: MockTestAddressRepository(),
        onVerified: (payload) => verifiedPayload = payload,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump(const Duration(milliseconds: 100));

      expect(verifiedPayload, isNotNull);
      expect(verifiedPayload?['isNewUser'], isTrue);
      expect(verifiedPayload?['destination'], equals(RouteNames.profileSetup));
    });

    testWidgets('Test 2 — Existing user with complete profile & address resolves to Dashboard (Home)',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      Map<String, dynamic>? verifiedPayload;

      await tester.pumpWidget(_buildTestApp(
        localStorage: localStorage,
        authRepo: MockTestAuthRepository(isNewUser: false, userName: 'Aarav Sharma'),
        profileRepo: MockTestProfileRepository(
          profileData: {
            'id': 'user_123',
            'phone': '+919876543210',
            'name': 'Aarav Sharma',
          },
        ),
        addressRepo: MockTestAddressRepository(
          addresses: [
            {
              'id': 'addr_123',
              'title': 'Home',
              'addressLine': 'Flat 402, Green Meadows',
              'city': 'Rajkot',
              'state': 'Gujarat',
              'pincode': '360005',
              'isDefault': true,
            }
          ],
        ),
        onVerified: (payload) => verifiedPayload = payload,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump(const Duration(milliseconds: 100));

      expect(verifiedPayload, isNotNull);
      expect(verifiedPayload?['isNewUser'], isFalse);
      expect(verifiedPayload?['destination'], equals(RouteNames.home));

      // Check local cache was synchronized
      expect(localStorage.getBool(AppConstants.keyProfileCompleted), isTrue);
      expect(localStorage.getBool(AppConstants.keyAddressCompleted), isTrue);
    });

    testWidgets('Test 3 — Existing user with incomplete profile resolves to Profile Setup',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      Map<String, dynamic>? verifiedPayload;

      await tester.pumpWidget(_buildTestApp(
        localStorage: localStorage,
        authRepo: MockTestAuthRepository(isNewUser: false, userName: null),
        profileRepo: MockTestProfileRepository(
          profileData: {
            'id': 'user_123',
            'phone': '+919876543210',
            'name': null,
          },
        ),
        addressRepo: MockTestAddressRepository(),
        onVerified: (payload) => verifiedPayload = payload,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump(const Duration(milliseconds: 100));

      expect(verifiedPayload, isNotNull);
      expect(verifiedPayload?['destination'], equals(RouteNames.profileSetup));
    });

    testWidgets('Test 4 — Existing user with complete profile but no address resolves to First-Time Address',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      Map<String, dynamic>? verifiedPayload;

      await tester.pumpWidget(_buildTestApp(
        localStorage: localStorage,
        authRepo: MockTestAuthRepository(isNewUser: false, userName: 'Aarav Sharma'),
        profileRepo: MockTestProfileRepository(
          profileData: {
            'id': 'user_123',
            'phone': '+919876543210',
            'name': 'Aarav Sharma',
          },
        ),
        addressRepo: MockTestAddressRepository(addresses: []),
        onVerified: (payload) => verifiedPayload = payload,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump(const Duration(milliseconds: 100));

      expect(verifiedPayload, isNotNull);
      expect(verifiedPayload?['destination'], equals(RouteNames.firstTimeAddAddress));
      expect(localStorage.getBool(AppConstants.keyProfileCompleted), isTrue);
      expect(localStorage.getBool(AppConstants.keyAddressCompleted), isNull);
    });

    testWidgets('Test 5 — Existing user + API failure does NOT route to Dashboard, shows error message',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      Map<String, dynamic>? verifiedPayload;

      await tester.pumpWidget(_buildTestApp(
        localStorage: localStorage,
        authRepo: MockTestAuthRepository(isNewUser: false, userName: 'Aarav Sharma'),
        profileRepo: MockTestProfileRepository(throwError: true),
        addressRepo: MockTestAddressRepository(),
        onVerified: (payload) => verifiedPayload = payload,
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump(const Duration(milliseconds: 100));

      // Must not succeed navigation
      expect(verifiedPayload, isNull);
      // User stays on Screen 05 with error message
      expect(find.byType(VerifyOtpScreen), findsOneWidget);
      expect(find.text('Profile service unavailable.'), findsOneWidget);
    });
  });
}
