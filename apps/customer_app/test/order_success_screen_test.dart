import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/features/orders/presentation/screens/order_success_screen.dart';
import 'package:customer_app/features/orders/presentation/widgets/order_success_card.dart';
import 'package:customer_app/shared/widgets/app_header.dart';

Widget _createOrderSuccessTestWidget({
  Map<String, dynamic>? orderData,
  String? orderId,
  GoRouter? customRouter,
  ThemeMode themeMode = ThemeMode.light,
}) {
  if (customRouter != null) {
    return ProviderScope(
      child: MaterialApp.router(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        routerConfig: customRouter,
      ),
    );
  }

  return ProviderScope(
    child: MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: OrderSuccessScreen(
        orderData: orderData,
        orderId: orderId,
      ),
    ),
  );
}

final _sampleOrderData = {
  'order': {
    'id': 'order_sample_001',
    'orderNumber': '#UB-270926-001',
    'total': 500.0,
    'itemCount': 3,
    'paymentMethod': 'ONLINE',
  },
  'orderNumber': '#UB-270926-001',
  'totalAmount': 500.0,
  'itemCount': 3,
  'paymentMethod': 'ONLINE',
  'paymentDetail': 'UPI',
  'address': {
    'type': 'Home',
    'receiverName': 'Maulik Patel',
    'addressLine': '123, Example Road, Green Heights, Opp. Central Park',
    'landmark': 'Near Lake',
    'city': 'Ahmedabad',
    'phone': '+91 98765 43210',
  },
};

void main() {
  group('Screen 20 — Order Success Tests', () {
    testWidgets('1. Screen renders successfully with all core sections', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      expect(find.byType(OrderSuccessScreen), findsOneWidget);
      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.byType(OrderSuccessCard), findsOneWidget);
      expect(find.byKey(const Key('order_success_track_button')), findsOneWidget);
      expect(find.byKey(const Key('order_success_continue_shopping')), findsOneWidget);
    });

    testWidgets('2. Header displays UNIQUE BASKET and no back button', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      expect(find.text('UNIQUE BASKET'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('3. Success message and checkmark graphic are displayed', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.textContaining('Your order is confirmed'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('4. Actual order number is displayed correctly', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      expect(find.text('ORDER ID'), findsOneWidget);
      expect(find.text('#UB-270926-001'), findsOneWidget);
    });

    testWidgets('5. Actual total is displayed correctly formatted with CurrencyFormatter', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL PAID'), findsOneWidget);
      expect(find.text('₹500'), findsOneWidget);
    });

    testWidgets('6. Actual item count is displayed', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      expect(find.text('3 items'), findsOneWidget);
    });

    testWidgets('7. UPI payment method displays correctly', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      expect(find.textContaining('Paid via UPI'), findsOneWidget);
    });

    testWidgets('8. COD payment method displays Cash on Delivery', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final codData = {
        ..._sampleOrderData,
        'paymentMethod': 'COD',
        'paymentDetail': 'Cash on Delivery',
        'order': {
          ...(_sampleOrderData['order'] as Map<String, dynamic>),
          'paymentMethod': 'COD',
        },
      };

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: codData));
      await tester.pumpAndSettle();

      expect(find.text('Cash on Delivery'), findsOneWidget);
    });

    testWidgets('9. Delivery address and receiver name display correctly', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      expect(find.text('Home • Maulik Patel'), findsOneWidget);
      expect(find.textContaining('123, Example Road'), findsOneWidget);
    });

    testWidgets('10. Track Order button navigates to RouteNames.orderTracking', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: RouteNames.orderSuccess,
        routes: [
          GoRoute(
            path: RouteNames.orderSuccess,
            builder: (context, state) => OrderSuccessScreen(
              orderData: _sampleOrderData,
            ),
          ),
          GoRoute(
            path: RouteNames.orderTracking,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return Scaffold(
                body: Center(
                  child: Text('Tracking Order: ${extra?['orderNumber']}'),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(_createOrderSuccessTestWidget(customRouter: router));
      await tester.pumpAndSettle();

      final trackButton = find.byKey(const Key('order_success_track_button'));
      expect(trackButton, findsOneWidget);
      await tester.tap(trackButton);
      await tester.pumpAndSettle();

      expect(find.text('Tracking Order: #UB-270926-001'), findsOneWidget);
    });

    testWidgets('11. Continue Shopping navigates to RouteNames.home', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: RouteNames.orderSuccess,
        routes: [
          GoRoute(
            path: RouteNames.orderSuccess,
            builder: (context, state) => OrderSuccessScreen(
              orderData: _sampleOrderData,
            ),
          ),
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Home Screen')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(_createOrderSuccessTestWidget(customRouter: router));
      await tester.pumpAndSettle();

      final continueShopping = find.byKey(const Key('order_success_continue_shopping'));
      expect(continueShopping, findsOneWidget);
      await tester.tap(continueShopping);
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('12. Back navigation (PopScope) safely returns to Home', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: RouteNames.orderSuccess,
        routes: [
          GoRoute(
            path: RouteNames.orderSuccess,
            builder: (context, state) => OrderSuccessScreen(
              orderData: _sampleOrderData,
            ),
          ),
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Home Screen Safe Terminal')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(_createOrderSuccessTestWidget(customRouter: router));
      await tester.pumpAndSettle();

      // Trigger system pop / back via onPopInvokedWithResult
      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope && w.child is Scaffold);
      expect(popScopeFinder, findsOneWidget);
      final popScope = tester.widget<PopScope>(popScopeFinder);
      popScope.onPopInvokedWithResult!(false, null);
      await tester.pumpAndSettle();

      expect(find.text('Home Screen Safe Terminal'), findsOneWidget);
    });

    testWidgets('13. Long address, recipient name, and order numbers do not overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final longData = {
        'orderNumber': 'UB-20260908-015-EXTRA-LONG-ORDER-ID-999999999',
        'totalAmount': 199999.75,
        'itemCount': 120,
        'paymentMethod': 'ONLINE',
        'paymentDetail': 'Google Pay UPI Transaction #1234567890',
        'address': {
          'type': 'Office / Corporate Headquarters',
          'receiverName': 'Shri Maulik Patel, Chief Technology Officer',
          'addressLine':
              'Plot No. 456-B, Extended Industrial Growth Center, Near International Logistics Hub, Sector 28-A',
          'landmark': 'Opposite Metro Pillar 189 & High Voltage Power Station',
          'city': 'Ahmedabad, Gujarat 380001, India',
          'phone': '+91 98765 43210',
        },
      };

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: longData));
      await tester.pumpAndSettle();

      expect(find.textContaining('UB-20260908-015'), findsOneWidget);
      expect(find.textContaining('120 items'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. 320dp responsive layout renders cleanly with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 600 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.byKey(const Key('order_success_track_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. 390dp responsive layout renders cleanly with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.byKey(const Key('order_success_track_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('16. 430dp responsive layout renders cleanly with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(430 * 3, 932 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.byKey(const Key('order_success_track_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17. Screen does not expose checkout/cart navigation that could duplicate order placement', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(orderData: _sampleOrderData));
      await tester.pumpAndSettle();

      // Ensure no "Place Order" or "Checkout" or "Add to Cart" CTA is accessible on Screen 20
      expect(find.text('PLACE ORDER'), findsNothing);
      expect(find.text('Proceed to Checkout'), findsNothing);
      expect(find.text('Checkout'), findsNothing);
    });

    testWidgets('18. Dark mode renders correctly with dark theme colors', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderSuccessTestWidget(
        orderData: _sampleOrderData,
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.byType(OrderSuccessCard), findsOneWidget);
    });
  });
}
