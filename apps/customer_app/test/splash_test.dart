import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/services/startup_state_resolver.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _createTestWidget({
  required Widget child,
  ThemeMode themeMode = ThemeMode.light,
  LocalStorageService? localStorage,
  SecureStorageService? secureStorage,
}) {
  return ProviderScope(
    overrides: [
      if (localStorage != null)
        localStorageProvider.overrideWithValue(localStorage),
      if (secureStorage != null)
        secureStorageProvider.overrideWithValue(secureStorage),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    AppConfig.initialize(
      appName: 'Unique Basket',
      environment: Environment.development,
    );
  });

  group('SplashScreen Unit & Widget Tests', () {
    test('Splash route constants are defined correctly', () {
      expect(RouteNames.splash, equals('/'));
      expect(RouteNames.initial, equals('/'));
      expect(RouteNames.placeholder, equals('/placeholder'));
    });

    test('Logo asset path constant points to approved runtime asset', () {
      expect(
        SplashScreen.logoAssetPath,
        equals('assets/logos/unique_basket_logo.png'),
      );
    });

    testWidgets('SplashScreen renders logo image without throwing',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      await tester.pumpWidget(
        _createTestWidget(
          localStorage: localStorage,
          child: const SplashScreen(
            splashDuration: Duration(milliseconds: 500),
            animationDuration: Duration(milliseconds: 200),
          ),
        ),
      );

      // Verify the image widget with correct asset name is present
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(
        (imageWidget.image as AssetImage).assetName,
        equals('assets/logos/unique_basket_logo.png'),
      );

      // Advance clock through the animation
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('SplashScreen triggers navigation callback and resolves brand-new user to onboarding',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      bool navigated = false;
      StartupDestination? resolvedDest;

      await tester.pumpWidget(
        _createTestWidget(
          localStorage: localStorage,
          child: SplashScreen(
            splashDuration: const Duration(milliseconds: 300),
            animationDuration: const Duration(milliseconds: 100),
            onNavigate: () {
              navigated = true;
            },
            onDestinationResolved: (dest) {
              resolvedDest = dest;
            },
          ),
        ),
      );

      expect(navigated, isFalse);

      // Advance time past splashDuration
      await tester.pump(const Duration(milliseconds: 150));
      expect(navigated, isFalse);

      await tester.pump(const Duration(milliseconds: 200));
      expect(navigated, isTrue);
      expect(resolvedDest, equals(StartupDestination.onboarding));
    });

    testWidgets('SplashScreen resolves returning user to home when all steps completed',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
        AppConstants.keyAddressCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      // Mock secure storage with valid token
      final exp = (DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch ~/ 1000);
      final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}))).replaceAll('=', '');
      final payload = base64Url.encode(utf8.encode(jsonEncode({'id': 'u1', 'exp': exp}))).replaceAll('=', '');
      final validJwt = '$header.$payload.mock_signature';

      final secureStorage = SecureStorageService();
      await secureStorage.saveTokens(accessToken: validJwt);

      StartupDestination? resolvedDest;

      await tester.pumpWidget(
        _createTestWidget(
          localStorage: localStorage,
          secureStorage: secureStorage,
          child: SplashScreen(
            splashDuration: const Duration(milliseconds: 200),
            animationDuration: const Duration(milliseconds: 100),
            onDestinationResolved: (dest) {
              resolvedDest = dest;
            },
            onNavigate: () {},
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 250));
      expect(resolvedDest, equals(StartupDestination.home));
    });

    testWidgets('SplashScreen handles reduced motion / disabled animations',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      await tester.pumpWidget(
        _createTestWidget(
          localStorage: localStorage,
          child: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: SplashScreen(
              splashDuration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Initial frame should render without throwing
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);

      // Advance clock
      await tester.pump(const Duration(milliseconds: 350));
    });

    testWidgets('SplashScreen respects dark theme background without errors',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      await tester.pumpWidget(
        _createTestWidget(
          localStorage: localStorage,
          themeMode: ThemeMode.dark,
          child: const SplashScreen(
            splashDuration: Duration(milliseconds: 300),
          ),
        ),
      );

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 350));
    });
  });
}
