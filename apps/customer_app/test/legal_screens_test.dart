import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/app_router.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:customer_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:customer_app/features/authentication/presentation/screens/mobile_number_screen.dart';
import 'package:customer_app/features/legal/presentation/screens/privacy_policy_screen.dart';
import 'package:customer_app/features/legal/presentation/screens/terms_and_conditions_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLegalAuthRepository implements AuthRepository {
  @override
  Future<void> sendOtp(String phoneNumber) async {}

  @override
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    return {'success': true};
  }

  @override
  Future<String?> refreshToken(String refreshToken) async {
    return 'mock_access_token';
  }
}

class MockLegalSecureStorageService implements SecureStorageService {
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

Widget _createLegalApp({
  required LocalStorageService localStorage,
}) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(localStorage),
      secureStorageProvider.overrideWithValue(MockLegalSecureStorageService()),
      authRepositoryProvider.overrideWithValue(MockLegalAuthRepository()),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: router,
        );
      },
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

  group('Legal Screens & Navigation Tests (Screen 35 & Screen 36)', () {
    test('1. Route constants for Terms & Conditions and Privacy Policy are correct', () {
      expect(RouteNames.termsAndConditions, equals('/terms-and-conditions'));
      expect(RouteNames.privacyPolicy, equals('/privacy-policy'));
    });

    testWidgets('2. Terms & Conditions screen renders all 10 sections and UI elements',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TermsAndConditionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TermsAndConditionsScreen), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsNWidgets(2)); // AppBar + Title
      expect(find.byIcon(Icons.public_rounded), findsOneWidget);
      expect(find.textContaining('Welcome to UNIQUE BASKET'), findsOneWidget);

      // Verify sections
      expect(find.text('1. About UNIQUE BASKET'), findsOneWidget);
      expect(find.text('2. Using Our Service'), findsOneWidget);
      expect(find.text('3. Account & Mobile Number'), findsOneWidget);
      expect(find.text('4. Products & Pricing'), findsOneWidget);
      expect(find.text('5. Delivery'), findsOneWidget);
      expect(find.text('6. Orders'), findsOneWidget);
      expect(find.text('7. Payments'), findsOneWidget);
      expect(find.text('8. Cancellation & Refunds'), findsOneWidget);
      expect(find.text('9. Changes to These Terms'), findsOneWidget);
      expect(find.text('10. Contact'), findsOneWidget);

      expect(find.textContaining('© UNIQUE BASKET. All rights reserved.'), findsOneWidget);
    });

    testWidgets('3. Privacy Policy screen renders all 7 sections and UI elements',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PrivacyPolicyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('Privacy Policy'), findsNWidgets(2)); // AppBar + Title
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.textContaining('At UNIQUE BASKET, we respect your privacy'), findsOneWidget);

      // Verify sections
      expect(find.text('1. Information We Collect'), findsOneWidget);
      expect(find.text('2. How We Use Your Information'), findsOneWidget);
      expect(find.text('3. Payment Information'), findsOneWidget);
      expect(find.text('4. Sharing of Information'), findsOneWidget);
      expect(find.text('5. Data Security'), findsOneWidget);
      expect(find.text('6. Your Choices'), findsOneWidget);
      expect(find.text('7. Changes to This Policy'), findsOneWidget);

      expect(find.textContaining('© UNIQUE BASKET. All rights reserved.'), findsOneWidget);
    });

    testWidgets('4. Screen 04: Tapping Terms & Conditions navigates to Screen 35 and back',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createLegalApp(localStorage: localStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      // We are on Screen 04
      expect(find.byType(MobileNumberScreen), findsOneWidget);

      // Enter a mobile number to test state preservation
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pump();

      // Trigger Terms & Conditions TapGestureRecognizer
      final richTextFinder = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Terms & Conditions'),
      );
      expect(richTextFinder, findsOneWidget);
      final richTextWidget = tester.widget<RichText>(richTextFinder);

      TapGestureRecognizer? termsRecognizer;
      richTextWidget.text.visitChildren((span) {
        if (span is TextSpan &&
            span.text == 'Terms & Conditions' &&
            span.recognizer is TapGestureRecognizer) {
          termsRecognizer = span.recognizer as TapGestureRecognizer;
          return false;
        }
        return true;
      });

      expect(termsRecognizer, isNotNull);
      termsRecognizer!.onTap!();
      await tester.pumpAndSettle();

      // Verify on Screen 35
      expect(find.byType(TermsAndConditionsScreen), findsOneWidget);

      // Tap Back button on Screen 35
      await tester.tap(find.byKey(const Key('terms_back_button')));
      await tester.pumpAndSettle();

      // Verify back on Screen 04 with phone number preserved
      expect(find.byType(MobileNumberScreen), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('9876543210'));
    });

    testWidgets('5. Screen 04: Tapping Privacy Policy navigates to Screen 36 and back',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createLegalApp(localStorage: localStorage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      // We are on Screen 04
      expect(find.byType(MobileNumberScreen), findsOneWidget);

      // Enter a mobile number to test state preservation
      await tester.enterText(find.byType(TextField), '9123456789');
      await tester.pump();

      // Trigger Privacy Policy TapGestureRecognizer
      final richTextFinder = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Privacy Policy'),
      );
      expect(richTextFinder, findsOneWidget);
      final richTextWidget = tester.widget<RichText>(richTextFinder);

      TapGestureRecognizer? privacyRecognizer;
      richTextWidget.text.visitChildren((span) {
        if (span is TextSpan &&
            span.text == 'Privacy Policy' &&
            span.recognizer is TapGestureRecognizer) {
          privacyRecognizer = span.recognizer as TapGestureRecognizer;
          return false;
        }
        return true;
      });

      expect(privacyRecognizer, isNotNull);
      privacyRecognizer!.onTap!();
      await tester.pumpAndSettle();

      // Verify on Screen 36
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);

      // Tap Back button on Screen 36
      await tester.tap(find.byKey(const Key('privacy_back_button')));
      await tester.pumpAndSettle();

      // Verify back on Screen 04 with phone number preserved
      expect(find.byType(MobileNumberScreen), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('9123456789'));
    });

    testWidgets('6. Dark theme renders both legal screens cleanly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const TermsAndConditionsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TermsAndConditionsScreen), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const PrivacyPolicyScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    });
  });
}
