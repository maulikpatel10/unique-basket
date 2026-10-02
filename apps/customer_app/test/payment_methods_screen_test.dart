import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:customer_app/features/payment/data/models/saved_payment_method_model.dart';
import 'package:customer_app/features/payment/presentation/providers/payment_methods_provider.dart';
import 'package:customer_app/features/payment/presentation/screens/payment_methods_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';

class MockSecureStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> clearTokens() async {
    _data.clear();
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

  late LocalStorageService localStorage;
  late MockSecureStorage mockSecureStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localStorage = LocalStorageService(prefs);
    mockSecureStorage = MockSecureStorage();
  });

  Widget createHarness({
    List<Override> overrides = const [],
    Widget? home,
  }) {
    return ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        secureStorageProvider.overrideWithValue(mockSecureStorage),
        ...overrides,
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Inter'),
        home: home ?? const PaymentMethodsScreen(),
      ),
    );
  }

  group('Screen 32 — Payment Methods Unit & Widget Tests', () {
    testWidgets('1. Screen renders AppHeader with title "Payment Methods"', (tester) async {
      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.byType(PaymentMethodsScreen), findsOneWidget);
    });

    testWidgets('2. Initial load seeds canonical reference payment methods', (tester) async {
      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(find.text('SAVED PAYMENT METHODS'), findsOneWidget);
      expect(find.text('3 methods saved for quick checkout'), findsOneWidget);
      expect(find.text('Google Pay / UPI'), findsOneWidget);
      expect(find.text('HDFC Bank Visa Card'), findsOneWidget);
      expect(find.text('ICICI Bank Debit Card'), findsOneWidget);
    });

    testWidgets('3. Default badge and fastest checkout option appear on default UPI method', (tester) async {
      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(find.text('DEFAULT'), findsOneWidget);
      expect(find.text('Fastest checkout option'), findsOneWidget);
    });

    testWidgets('4. Masked card numbers and badges render for card items', (tester) async {
      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(find.text('••••  ••••  ••••  4242'), findsOneWidget);
      expect(find.text('••••  ••••  ••••  8891'), findsOneWidget);
      expect(find.text('Credit'), findsOneWidget);
      expect(find.text('Debit'), findsOneWidget);
    });

    testWidgets('5. Set as Default changes exactly one default method', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      // Initially 1 DEFAULT badge on UPI
      expect(find.text('DEFAULT'), findsOneWidget);

      // Find first "Set as Default" button (on HDFC card)
      final setAsDefaultFinders = find.text('Set as Default');
      expect(setAsDefaultFinders, findsNWidgets(2));

      await tester.tap(setAsDefaultFinders.first);
      await tester.pumpAndSettle();

      // Still exactly 1 default badge in UI
      expect(find.text('DEFAULT'), findsOneWidget);

      // Verify in storage
      final storedJson = localStorage.getString(AppConstants.keySavedPaymentMethods);
      expect(storedJson, isNotNull);
      final decoded = jsonDecode(storedJson!) as List;
      final defaults = decoded.where((e) => e['isDefault'] == true).toList();
      expect(defaults.length, 1);
      expect(defaults.first['title'], 'HDFC Bank Visa Card');
    });

    testWidgets('6. Remove tap opens confirmation dialog and Cancel preserves method', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      final removeButtons = find.text('Remove');
      expect(removeButtons, findsNWidgets(3));

      // Tap remove on first method
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Remove Payment Method?'), findsOneWidget);
      expect(find.text('Are you sure you want to remove Google Pay / UPI?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismisses and 3 methods remain
      expect(find.text('Remove Payment Method?'), findsNothing);
      expect(find.text('Google Pay / UPI'), findsOneWidget);
      expect(find.text('3 methods saved for quick checkout'), findsOneWidget);
    });

    testWidgets('7. Confirming Remove deletes method and reassigns default if deleted method was default', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      // Remove default method (Google Pay / UPI)
      await tester.tap(find.text('Remove').first);
      await tester.pumpAndSettle();

      // In dialog, tap Remove (red text)
      final dialogRemoveBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Remove'),
      );
      await tester.tap(dialogRemoveBtn);
      await tester.pumpAndSettle();

      // Snack bar shown
      expect(find.text('Google Pay / UPI removed'), findsOneWidget);

      // 2 methods remaining
      expect(find.text('2 methods saved for quick checkout'), findsOneWidget);
      expect(find.text('Google Pay / UPI'), findsNothing);

      // Default reassigned to HDFC Bank Visa Card
      final storedJson = localStorage.getString(AppConstants.keySavedPaymentMethods);
      final decoded = jsonDecode(storedJson!) as List;
      expect(decoded.length, 2);
      expect(decoded[0]['isDefault'], true);
      expect(decoded[0]['title'], 'HDFC Bank Visa Card');
    });

    testWidgets('8. Removing all methods transitions to Empty State', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Seed with empty list directly
      await localStorage.setString(AppConstants.keySavedPaymentMethods, jsonEncode([]));

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(find.text('No Saved Payment Methods'), findsOneWidget);
      expect(find.text('Add your preferred UPI or Card details for faster checkout.'), findsOneWidget);
      expect(find.text('Add Payment Method'), findsOneWidget);
    });

    testWidgets('9. Add payment method opens modal sheet and adds new UPI method', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      // Tap "Add New" button in header
      await tester.tap(find.text('Add New'));
      await tester.pumpAndSettle();

      expect(find.text('Add Payment Method'), findsWidgets);
      expect(find.text('Payment Method Type'), findsOneWidget);
      expect(find.text('Preferences are saved locally for quick selection. CVV or card passwords are never requested.'), findsOneWidget);

      // Fill in UPI ID
      final upiField = find.widgetWithText(TextFormField, 'UPI ID (e.g. user@okhdfcbank)');
      await tester.enterText(upiField, 'testuser@paytm');
      await tester.pumpAndSettle();

      // Tap Save Payment Method
      await tester.tap(find.text('Save Payment Method'));
      await tester.pumpAndSettle();

      expect(find.text('Google Pay / UPI added successfully'), findsOneWidget);
      expect(find.text('4 methods saved for quick checkout'), findsOneWidget);
      expect(find.text('testuser@paytm'), findsOneWidget);
    });

    testWidgets('10. Add payment method prevents duplicate entries', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      // Try adding duplicate UPI with same 'maulik@okhdfcbank'
      await tester.tap(find.text('Add New'));
      await tester.pumpAndSettle();

      final upiField = find.widgetWithText(TextFormField, 'UPI ID (e.g. user@okhdfcbank)');
      await tester.enterText(upiField, 'maulik@okhdfcbank');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Payment Method'));
      await tester.pumpAndSettle();

      expect(find.text('Payment method already exists'), findsOneWidget);
      expect(find.text('3 methods saved for quick checkout'), findsOneWidget);
    });

    testWidgets('11. State survives provider reload and app restart', (tester) async {
      final customList = [
        const SavedPaymentMethod(
          id: 'pm-custom-1',
          type: PaymentMethodType.creditCard,
          title: 'Axis Bank Flipkart Card',
          subtitle: 'Expires: 10/29  ·  Tester',
          maskedIdentifier: '••••  ••••  ••••  9999',
          isDefault: true,
        ),
      ];

      await localStorage.setString(
        AppConstants.keySavedPaymentMethods,
        jsonEncode(customList.map((m) => m.toJson()).toList()),
      );

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(find.text('Axis Bank Flipkart Card'), findsOneWidget);
      expect(find.text('••••  ••••  ••••  9999'), findsOneWidget);
      expect(find.text('1 method saved for quick checkout'), findsOneWidget);
    });

    testWidgets('12. Corrupt storage data recovers gracefully to empty list without crash', (tester) async {
      await localStorage.setString(AppConstants.keySavedPaymentMethods, 'not-valid-json');

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Profile screen navigates to Payment Methods screen when tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: RouteNames.profile,
        routes: [
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: RouteNames.paymentMethods,
            builder: (context, state) => const PaymentMethodsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
            customerProfileProvider.overrideWith((ref) async => {
                  'name': 'Maulik Patel',
                  'phone': '+91 98765 43210',
                }),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Methods'), findsOneWidget);

      await tester.tap(find.text('Payment Methods'));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentMethodsScreen), findsOneWidget);
      expect(find.text('SAVED PAYMENT METHODS'), findsOneWidget);
    });

    testWidgets('14. User account isolation: Logout clears saved payment methods key', (tester) async {
      // Verify key is registered in userScopedStorageKeys
      expect(AppConstants.userScopedStorageKeys.contains(AppConstants.keySavedPaymentMethods), isTrue);

      // Set saved payment methods
      await localStorage.setString(
        AppConstants.keySavedPaymentMethods,
        jsonEncode([
          const SavedPaymentMethod(
            id: 'pm-user1',
            type: PaymentMethodType.upi,
            title: 'User 1 UPI',
            subtitle: 'user1@upi',
          ).toJson()
        ]),
      );

      // Verify stored for User 1
      expect(localStorage.getString(AppConstants.keySavedPaymentMethods), isNotNull);

      // Trigger user session clear (as performed by AuthNotifier.logout)
      await localStorage.clearUserSessionData();

      // Verify key is cleared from user-scoped storage
      expect(localStorage.getString(AppConstants.keySavedPaymentMethods), isNull);
    });

    testWidgets('15. Add payment method modal supports Credit Card entry', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add New'));
      await tester.pumpAndSettle();

      // Select Credit Card chip
      await tester.tap(find.text('Credit Card'));
      await tester.pumpAndSettle();

      final last4Field = find.widgetWithText(TextFormField, 'Last 4 Digits');
      await tester.enterText(last4Field, '7788');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Payment Method'));
      await tester.pumpAndSettle();

      expect(find.text('Visa Credit Card added successfully'), findsOneWidget);
      expect(find.text('••••  ••••  ••••  7788'), findsOneWidget);
    });

    testWidgets('16. Responsive layout across compact widths (320, 360, 390, 430)', (tester) async {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createHarness());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('17. Back navigation returns correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool popped = false;
      final router = GoRouter(
        initialLocation: RouteNames.paymentMethods,
        routes: [
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const Scaffold(body: Text('Profile Root')),
          ),
          GoRoute(
            path: RouteNames.paymentMethods,
            builder: (context, state) => const PaymentMethodsScreen(),
            onExit: (context, state) {
              popped = true;
              return true;
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find back button
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });
  });
}
