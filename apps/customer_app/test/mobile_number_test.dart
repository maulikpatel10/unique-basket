import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:customer_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:customer_app/features/authentication/presentation/screens/mobile_number_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMobileAuthRepository implements AuthRepository {
  bool sendOtpSuccess = true;
  String? lastRequestedPhone;
  int sendOtpCallCount = 0;

  @override
  Future<void> sendOtp(String phoneNumber) async {
    sendOtpCallCount++;
    lastRequestedPhone = phoneNumber;
    if (!sendOtpSuccess) {
      throw Exception('Server error');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    return {'success': true};
  }
}

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

Widget _createTestWidget({
  MockMobileAuthRepository? mockAuthRepo,
  ValueChanged<String>? onOtpRequested,
  ThemeMode themeMode = ThemeMode.light,
  LocalStorageService? localStorage,
}) {
  return ProviderScope(
    overrides: [
      if (localStorage != null)
        localStorageProvider.overrideWithValue(localStorage),
      secureStorageProvider.overrideWithValue(MockSecureStorageService()),
      if (mockAuthRepo != null)
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: MobileNumberScreen(
        onOtpRequested: onOtpRequested,
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

  group('Screen 04 — Mobile Number Screen Tests', () {
    test('Mobile number route constants are defined correctly', () {
      expect(RouteNames.mobileNumber, equals('/auth/mobile'));
    });

    testWidgets('1. Screen 04 renders logo, phone input field, and continue button',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(localStorage: localStorage));
      await tester.pump();

      expect(find.byType(MobileNumberScreen), findsOneWidget);
      expect(find.text('MOBILE NUMBER'), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('2. Entering valid 10-digit phone triggers OTP request on Continue',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockAuth = MockMobileAuthRepository();
      String? requestedPhone;

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        mockAuthRepo: mockAuth,
        onOtpRequested: (phone) => requestedPhone = phone,
      ));
      await tester.pump();

      final phoneInput = find.byType(TextField);
      expect(phoneInput, findsOneWidget);
      await tester.enterText(phoneInput, '9876543210');
      await tester.pump();

      final continueButton = find.text('Continue');
      await tester.tap(continueButton);
      await tester.pump();

      expect(requestedPhone, equals('+919876543210'));
    });

    testWidgets('3. Entering invalid phone number displays error message on Continue',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(localStorage: localStorage));
      await tester.pump();

      final phoneInput = find.byType(TextField);
      await tester.enterText(phoneInput, '12345');
      await tester.pump();

      final continueButton = find.text('Continue');
      await tester.tap(continueButton);
      await tester.pump();

      expect(find.text('Enter valid 10-digit mobile number'), findsOneWidget);
    });

    testWidgets('4. Dark theme renders cleanly', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        themeMode: ThemeMode.dark,
      ));
      await tester.pump();

      expect(find.byType(MobileNumberScreen), findsOneWidget);
      expect(find.text('MOBILE NUMBER'), findsOneWidget);
    });
  });
}
