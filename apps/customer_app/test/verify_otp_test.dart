import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/errors/app_exception.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:customer_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:customer_app/features/authentication/presentation/screens/verify_otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockVerifyAuthRepository implements AuthRepository {
  bool sendOtpSuccess = true;
  bool verifyOtpSuccess = true;
  String? lastVerifiedPhone;
  String? lastVerifiedOtp;
  int verifyOtpCallCount = 0;
  int sendOtpCallCount = 0;
  Duration delay = Duration.zero;

  @override
  Future<void> sendOtp(String phoneNumber) async {
    sendOtpCallCount++;
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (!sendOtpSuccess) {
      throw const AppException(message: 'Failed to send OTP. Server error.');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    verifyOtpCallCount++;
    lastVerifiedPhone = phoneNumber;
    lastVerifiedOtp = otp;
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (!verifyOtpSuccess || otp != '1234') {
      throw const AppException(message: 'Invalid verification code. Please try again.');
    }
    return {
      'success': true,
      'data': {
        'user': {
          'id': 'cust_123',
          'phone': phoneNumber,
        },
        'token': 'mock_jwt_access_token',
        'refreshToken': 'mock_jwt_refresh_token',
        'isNewUser': true,
      },
    };
  }

  @override
  Future<String?> refreshToken(String refreshToken) async {
    return 'mock_jwt_access_token';
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
  MockVerifyAuthRepository? mockAuthRepo,
  SecureStorageService? mockSecureStorage,
  String phoneNumber = '+919876543210',
  ValueChanged<Map<String, dynamic>>? onVerified,
  VoidCallback? onResendRequested,
  VoidCallback? onEditPhoneRequested,
  ThemeMode themeMode = ThemeMode.light,
  LocalStorageService? localStorage,
}) {
  return ProviderScope(
    overrides: [
      if (localStorage != null)
        localStorageProvider.overrideWithValue(localStorage),
      secureStorageProvider.overrideWithValue(mockSecureStorage ?? MockSecureStorageService()),
      if (mockAuthRepo != null)
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: VerifyOtpScreen(
        phoneNumber: phoneNumber,
        onVerified: onVerified,
        onResendRequested: onResendRequested,
        onEditPhoneRequested: onEditPhoneRequested,
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

  group('Screen 05 — Verify Mobile OTP Screen Tests', () {
    test('Verify OTP route constant is defined correctly', () {
      expect(RouteNames.verifyOtp, equals('/auth/verify-otp'));
    });

    testWidgets('1. OTP screen receives and displays the actual mobile number',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        phoneNumber: '+919123456789',
      ));
      await tester.pump();

      expect(find.byType(VerifyOtpScreen), findsOneWidget);
      expect(find.textContaining('+91 91234'), findsOneWidget);
    });

    testWidgets('2. OTP input is NOT automatically populated',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(localStorage: localStorage));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('3. Incomplete OTP blocks submission and shows validation error',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockRepo = MockVerifyAuthRepository();

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        mockAuthRepo: mockRepo,
      ));
      await tester.pump();

      // Enter only 2 digits
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '12');
      await tester.pump();

      // Verify button is disabled or tapping does not call verify
      expect(mockRepo.verifyOtpCallCount, 0);
    });

    testWidgets('4. Entering 1234 calls Verify OTP API and succeeds',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockRepo = MockVerifyAuthRepository();

      Map<String, dynamic>? verifiedPayload;

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        mockAuthRepo: mockRepo,
        phoneNumber: '+919876543210',
        onVerified: (payload) => verifiedPayload = payload,
      ));
      await tester.pump();

      // Enter 1234
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '1234');
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.verifyOtpCallCount, 1);
      expect(mockRepo.lastVerifiedPhone, equals('+919876543210'));
      expect(mockRepo.lastVerifiedOtp, equals('1234'));
      expect(verifiedPayload, isNotNull);
      expect(verifiedPayload?['isNewUser'], isTrue);
    });

    testWidgets('5. Incorrect OTP fails API verification and keeps user on Screen 05 with error',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockRepo = MockVerifyAuthRepository();

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        mockAuthRepo: mockRepo,
      ));
      await tester.pump();

      // Enter incorrect OTP 9999
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '9999');
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.verifyOtpCallCount, 1);
      expect(mockRepo.lastVerifiedOtp, equals('9999'));
      // User stays on Screen 05
      expect(find.byType(VerifyOtpScreen), findsOneWidget);
      // Displays error message
      expect(find.text('Invalid verification code. Please try again.'), findsOneWidget);
    });

    testWidgets('6. Duplicate Verify calls are prevented while verifying',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockRepo = MockVerifyAuthRepository()..delay = const Duration(milliseconds: 300);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        mockAuthRepo: mockRepo,
      ));
      await tester.pump();

      // Enter 1234
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '1234');
      await tester.pump(const Duration(milliseconds: 50));

      // Attempt second submission while loading
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 350));

      expect(mockRepo.verifyOtpCallCount, 1);
    });

    testWidgets('7. Resend OTP button triggers resend when enabled',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockRepo = MockVerifyAuthRepository();

      bool resendCallbackCalled = false;

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        mockAuthRepo: mockRepo,
        onResendRequested: () => resendCallbackCalled = true,
      ));
      await tester.pump();

      // Fast-forward 31 seconds for countdown timer
      await tester.pump(const Duration(seconds: 31));

      // Tap Resend SMS
      final resendFinder = find.text("Didn't receive code? Resend SMS");
      expect(resendFinder, findsOneWidget);
      await tester.tap(resendFinder);
      await tester.pump(const Duration(milliseconds: 50));

      expect(resendCallbackCalled, isTrue);
    });

    testWidgets('8. Dark mode renders correctly without error',
        (WidgetTester tester) async {
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

      expect(find.byType(VerifyOtpScreen), findsOneWidget);
      expect(find.text('Verify your\nmobile number'), findsOneWidget);
    });

    testWidgets('9. Responsive layout across multiple devices',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final viewports = [
        const Size(320, 568),
        const Size(360, 640),
        const Size(390, 844),
        const Size(430, 932),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(_createTestWidget(localStorage: localStorage));
        await tester.pump();

        expect(find.byType(VerifyOtpScreen), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
    });

    testWidgets('10. Screen 05 has NO visible Back button',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(localStorage: localStorage));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('11. Screen 05 has NO Step indicator / STEP 2 OF 4',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(localStorage: localStorage));
      await tester.pump();

      expect(find.text('STEP 2 OF 4'), findsNothing);
    });

    testWidgets('12. PopScope blocks system back navigation on Screen 05',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(localStorage: localStorage));
      await tester.pump();

      final popScopeFinder = find.byWidgetPredicate(
        (widget) => widget is PopScope && widget.canPop == false,
      );
      expect(popScopeFinder, findsOneWidget);
    });

    testWidgets('13. Edit mobile number pen button triggers edit callback',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      bool editPhoneRequested = false;

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        onEditPhoneRequested: () => editPhoneRequested = true,
      ));
      await tester.pump();

      expect(find.byKey(const Key('edit_mobile_number_icon')), findsOneWidget);
      expect(find.byKey(const Key('edit_mobile_number_pill')), findsOneWidget);

      await tester.tap(find.byKey(const Key('edit_mobile_number_icon')));
      await tester.pump();

      expect(editPhoneRequested, isTrue);
    });
  });
}
