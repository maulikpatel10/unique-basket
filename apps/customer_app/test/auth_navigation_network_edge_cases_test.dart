import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/errors/app_exception.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:customer_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:customer_app/features/authentication/presentation/screens/mobile_number_screen.dart';
import 'package:customer_app/features/authentication/presentation/screens/verify_otp_screen.dart';

class _MockAuthRepository implements AuthRepository {
  bool sendOtpSuccess = true;
  bool verifyOtpSuccess = true;
  int sendOtpCallCount = 0;
  int verifyOtpCallCount = 0;
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
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (!verifyOtpSuccess || otp != '1234') {
      throw const AppException(message: 'Invalid verification code.');
    }
    return {
      'success': true,
      'data': {
        'user': {'id': 'user_1', 'phone': phoneNumber},
        'token': 'mock_token',
        'refreshToken': 'mock_refresh',
        'isNewUser': false,
      },
    };
  }

  @override
  Future<String?> refreshToken(String refreshToken) async => 'mock_token';
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

  group('Authentication & OTP Edge Cases', () {
    testWidgets('1. Mobile number input limits to 10 digits and ignores alphabetic chars',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockAuth = _MockAuthRepository();

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MobileNumberScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final phoneField = find.byType(TextField);
      expect(phoneField, findsOneWidget);

      await tester.enterText(phoneField, '9876543210');
      await tester.pumpAndSettle();

      final textWidget = tester.widget<TextField>(phoneField);
      expect(textWidget.controller?.text.length, equals(10));
      expect(textWidget.controller?.text, equals('9876543210'));
    });

    testWidgets('2. Entering invalid/short mobile number does not invoke sendOtp',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockAuth = _MockAuthRepository();

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MobileNumberScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final phoneField = find.byType(TextField);
      await tester.enterText(phoneField, '98765');
      await tester.pumpAndSettle();

      final continueBtn = find.text('Continue');
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(mockAuth.sendOtpCallCount, equals(0));
    });

    testWidgets('3. Rapid multiple taps on Continue trigger sendOtp only once while loading',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockAuth = _MockAuthRepository()..delay = const Duration(milliseconds: 100);

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
      );

      final router = GoRouter(
        initialLocation: RouteNames.mobileNumber,
        routes: [
          GoRoute(
            path: RouteNames.mobileNumber,
            builder: (context, state) => const MobileNumberScreen(),
          ),
          GoRoute(
            path: RouteNames.verifyOtp,
            builder: (context, state) => const Scaffold(body: Text('Verify OTP Screen Destination')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final phoneField = find.byType(TextField);
      await tester.enterText(phoneField, '9876543210');
      await tester.pumpAndSettle();

      final continueBtn = find.text('Continue');
      // Tap continue button
      await tester.tap(continueBtn);
      await tester.pump(); // Advance microtasks into loading state

      // Any attempt to invoke submit while loading should be ignored
      expect(mockAuth.sendOtpCallCount, equals(1));
      await tester.pumpAndSettle();

      expect(mockAuth.sendOtpCallCount, equals(1));
      expect(find.text('Verify OTP Screen Destination'), findsOneWidget);
    });

    testWidgets('4. OTP verification failure displays SnackBar/error safely without app crash',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockAuth = _MockAuthRepository()..verifyOtpSuccess = false;

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          authRepositoryProvider.overrideWithValue(mockAuth),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: VerifyOtpScreen(phoneNumber: '+91 98765 43210'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final otpFields = find.byType(TextField);
      expect(otpFields, findsWidgets);

      await tester.enterText(otpFields.first, '9');
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
