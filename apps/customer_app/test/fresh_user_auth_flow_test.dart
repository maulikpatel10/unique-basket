import 'package:customer_app/app/app.dart';
import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/address/presentation/screens/first_time_add_address_screen.dart';
import 'package:customer_app/features/authentication/presentation/screens/mobile_number_screen.dart';
import 'package:customer_app/features/home/presentation/screens/home_screen.dart';
import 'package:customer_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:customer_app/features/profile_setup/presentation/screens/profile_setup_screen.dart';
import 'package:customer_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    AppConfig.initialize(
      appName: 'Unique Basket',
      environment: Environment.development,
    );
  });

  group('Fresh User Authentication Flow Tests', () {
    testWidgets('Scenario 1: Completely fresh user starts at Splash and navigates to Onboarding',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final secureStorage = SecureStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
            secureStorageProvider.overrideWithValue(secureStorage),
          ],
          child: const CustomerApp(),
        ),
      );

      // Initially on Splash
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);

      // Advance clock through splash delay
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      // Successfully navigated to Onboarding screen (NOT Dashboard/Home)
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Scenario 2: User with onboarding completed navigates from Splash to Mobile Number screen',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final secureStorage = SecureStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
            secureStorageProvider.overrideWithValue(secureStorage),
          ],
          child: const CustomerApp(),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      // Resolved to MobileNumberScreen
      expect(find.byType(MobileNumberScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Scenario 3: User with valid token but incomplete profile navigates to Profile Setup',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final secureStorage = SecureStorageService();
      await secureStorage.saveTokens(accessToken: 'mock_jwt_access_token');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
            secureStorageProvider.overrideWithValue(secureStorage),
          ],
          child: const CustomerApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      // Resolved to ProfileSetupScreen
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Scenario 4: User with profile completed but address incomplete navigates to First-Time Address',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final secureStorage = SecureStorageService();
      await secureStorage.saveTokens(accessToken: 'mock_jwt_access_token');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
            secureStorageProvider.overrideWithValue(secureStorage),
          ],
          child: const CustomerApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      // Resolved to FirstTimeAddAddressScreen
      expect(find.byType(FirstTimeAddAddressScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Scenario 5: Returning user with all steps completed navigates to Home / Dashboard',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingCompleted: true,
        AppConstants.keyProfileCompleted: true,
        AppConstants.keyAddressCompleted: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final secureStorage = SecureStorageService();
      await secureStorage.saveTokens(accessToken: 'mock_jwt_access_token');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
            secureStorageProvider.overrideWithValue(secureStorage),
          ],
          child: const CustomerApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      // Resolved to HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
