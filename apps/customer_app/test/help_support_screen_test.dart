import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/features/checkout/presentation/providers/order_provider.dart';
import 'package:customer_app/features/profile/presentation/screens/help_support_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService localStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localStorage = LocalStorageService(prefs);
  });

  Widget createHarness({
    List<Override> overrides = const [],
    Widget? home,
  }) {
    return ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        customerOrdersProvider.overrideWith((ref) async => []),
        ...overrides,
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Inter'),
        home: home ?? const HelpSupportScreen(),
      ),
    );
  }

  group('Screen 33 — Help & Support Unit & Widget Tests', () {
    testWidgets('1. Help & Support screen renders AppHeader with title', (tester) async {
      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.byType(HelpSupportScreen), findsOneWidget);
    });

    testWidgets('2. Profile Help & Support menu item navigates to Screen 33', (tester) async {
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
            path: RouteNames.helpSupport,
            builder: (context, state) => const HelpSupportScreen(),
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
            customerOrdersProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);

      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();

      expect(find.byType(HelpSupportScreen), findsOneWidget);
    });

    testWidgets('3. Search bar is displayed with correct placeholder', (tester) async {
      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search orders, payments, delivery...'), findsOneWidget);
    });

    testWidgets('4. Quick Help section displays Orders & Delivery and Payments & Refunds cards', (tester) async {
      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(find.text('QUICK HELP'), findsOneWidget);
      expect(find.text('Orders & Delivery'), findsOneWidget);
      expect(find.text('Track, modify, or get order assistance'), findsOneWidget);
      expect(find.text('Payments & Refunds'), findsOneWidget);
      expect(find.text('UPI, wallet, cashback & refund status'), findsOneWidget);
    });

    testWidgets('5. Orders & Delivery card opens help modal sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Orders & Delivery'));
      await tester.pumpAndSettle();

      expect(find.text('Orders & Delivery Help'), findsOneWidget);
      expect(find.text('How do I track my active order?'), findsOneWidget);
      expect(find.text('What are the delivery hours in Rajkot?'), findsOneWidget);
      expect(find.text('View My Orders'), findsOneWidget);
    });

    testWidgets('6. Payments & Refunds card opens help modal sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Payments & Refunds'));
      await tester.pumpAndSettle();

      expect(find.text('Payments & Refunds Help'), findsOneWidget);
      expect(find.text('What payment methods are supported?'), findsOneWidget);
      expect(find.text('How long does a refund take?'), findsOneWidget);
      expect(find.text('Manage Payment Methods'), findsOneWidget);
    });

    testWidgets('7. Search filters help topics and clears properly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      // Enter search term "refund"
      await tester.enterText(find.byType(TextField), 'refund');
      await tester.pumpAndSettle();

      expect(find.text('SEARCH RESULTS (2)'), findsOneWidget);
      expect(find.text('Refund Status & Timeline'), findsOneWidget);

      // Clear search
      final clearButton = find.byIcon(Icons.clear_rounded);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('QUICK HELP'), findsOneWidget);
    });

    testWidgets('8. Search handles empty results gracefully', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyznonexistent123');
      await tester.pumpAndSettle();

      expect(find.text('No matching help topics found'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      expect(find.text('QUICK HELP'), findsOneWidget);
    });

    testWidgets('9. Active order card renders when active order exists', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activeOrder = {
        'id': 'ord-123',
        'orderNumber': 'UB-20260908-015',
        'orderStatus': 'PREPARING',
        'totalAmount': 500.0,
        'itemCount': 3,
        'items': [
          {'id': 'item-1', 'name': 'Apples'},
          {'id': 'item-2', 'name': 'Bananas'},
          {'id': 'item-3', 'name': 'Milk'},
        ],
      };

      await tester.pumpWidget(
        createHarness(
          overrides: [
            customerOrdersProvider.overrideWith((ref) async => [activeOrder]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEED HELP WITH AN ORDER?'), findsOneWidget);
      expect(find.text('Active Order'), findsOneWidget);
      expect(find.text('#UB-20260908-015'), findsOneWidget);
      expect(find.text('Preparing your fresh groceries'), findsOneWidget);
      expect(find.text('₹500'), findsOneWidget);
      expect(find.text(' · 3 items'), findsOneWidget);
      expect(find.text('Get Help With This Order'), findsOneWidget);
    });

    testWidgets('10. Active order card does not appear when no active orders exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final deliveredOrder = {
        'id': 'ord-old-1',
        'orderNumber': 'UB-20260801-001',
        'orderStatus': 'DELIVERED',
        'totalAmount': 320.0,
        'itemCount': 2,
      };

      await tester.pumpWidget(
        createHarness(
          overrides: [
            customerOrdersProvider.overrideWith((ref) async => [deliveredOrder]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Active Orders'), findsOneWidget);
      expect(find.text('View Order History'), findsOneWidget);
    });

    testWidgets('11. Get Help With This Order tap opens action bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activeOrder = {
        'id': 'ord-123',
        'orderNumber': 'UB-20260908-015',
        'orderStatus': 'PREPARING',
        'totalAmount': 500.0,
        'itemCount': 3,
      };

      await tester.pumpWidget(
        createHarness(
          overrides: [
            customerOrdersProvider.overrideWith((ref) async => [activeOrder]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Help With This Order'));
      await tester.pumpAndSettle();

      expect(find.text('Help with #UB-20260908-015'), findsOneWidget);
      expect(find.text('Track Live Delivery'), findsOneWidget);
      expect(find.text('View Full Order Details'), findsOneWidget);
      expect(find.text('Contact Customer Support'), findsOneWidget);
    });

    testWidgets('12. Still Need Help section renders with Chat and Call actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      expect(find.text('Still need help?'), findsOneWidget);
      expect(find.text('Our customer care champions are always here for you.'), findsOneWidget);
      expect(find.text('Chat With Us'), findsOneWidget);
      expect(find.text('Call Support'), findsOneWidget);
    });

    testWidgets('13. Chat With Us opens support modal with official phone and email', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chat With Us'));
      await tester.pumpAndSettle();

      expect(find.text('Customer Support Chat'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('support@uniquebasket.com'), findsOneWidget);
      expect(find.text('Copy Contact'), findsOneWidget);

      await tester.tap(find.text('Copy Contact'));
      await tester.pumpAndSettle();

      expect(find.text('Support contact copied to clipboard (+91 98765 43210)'), findsOneWidget);
    });

    testWidgets('14. Call Support opens phone support dialog with configured phone number', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Call Support'));
      await tester.pumpAndSettle();

      expect(find.text('Speak directly with a UNIQUE BASKET customer care champion.'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('Call / Copy'), findsOneWidget);

      await tester.tap(find.text('Call / Copy'));
      await tester.pumpAndSettle();

      expect(find.text('Support phone number copied: +91 98765 43210'), findsOneWidget);
    });

    testWidgets('15. Order provider error state renders cleanly without crash', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createHarness(
          overrides: [
            customerOrdersProvider.overrideWith((ref) => Future.error(Exception('NETWORK_ERROR'))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('No Active Orders'), findsOneWidget);
    });

    testWidgets('16. Back button in AppHeader returns cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool popped = false;
      final router = GoRouter(
        initialLocation: RouteNames.helpSupport,
        routes: [
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const Scaffold(body: Text('Profile Screen')),
          ),
          GoRoute(
            path: RouteNames.helpSupport,
            builder: (context, state) => const HelpSupportScreen(),
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
            customerOrdersProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('17. Responsive layout across compact widths (320, 360, 390, 430)', (tester) async {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createHarness());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('18. Loading order state renders loading placeholder gracefully', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createHarness(
          overrides: [
            customerOrdersProvider.overrideWith((ref) => Future.delayed(const Duration(milliseconds: 50), () => [])),
          ],
        ),
      );
      await tester.pump(); // don't settle immediately to verify loading state

      expect(find.text('Checking active orders...'), findsOneWidget);

      await tester.pumpAndSettle(); // settle remaining timers cleanly
    });

    testWidgets('19. Search query matching order assistance shows relevant results', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHarness());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'track');
      await tester.pumpAndSettle();

      expect(find.text('Track Live Delivery'), findsOneWidget);
    });

    testWidgets('20. Dark theme renders cleanly without exception', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
            customerOrdersProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const HelpSupportScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Help & Support'), findsOneWidget);
    });
  });
}
