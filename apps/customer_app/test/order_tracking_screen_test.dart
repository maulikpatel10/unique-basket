import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/features/checkout/data/repositories/order_repository.dart';
import 'package:customer_app/features/checkout/presentation/providers/order_provider.dart';
import 'package:customer_app/features/orders/presentation/screens/order_success_screen.dart';
import 'package:customer_app/features/orders/presentation/screens/order_tracking_screen.dart';
import 'package:customer_app/features/orders/presentation/screens/order_details_screen.dart';
import 'package:customer_app/features/orders/presentation/widgets/order_items_delivery_card.dart';
import 'package:customer_app/features/orders/presentation/widgets/order_progress_timeline.dart';
import 'package:customer_app/features/orders/presentation/widgets/tracking_hero_banner.dart';
import 'package:customer_app/shared/widgets/app_header.dart';

class MockOrderTrackingRepository implements OrderRepository {
  bool shouldFail = false;
  bool returnNull = false;
  String? failureMessage;
  String currentStatus = 'PREPARING';

  @override
  Future<Map<String, dynamic>> createOrder({
    required String fulfillmentType,
    required String? addressId,
    required String? storeId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    if (shouldFail) {
      throw Exception(failureMessage ?? 'NETWORK_ERROR');
    }
    if (returnNull) {
      return {'success': false, 'data': null};
    }
    return {
      'success': true,
      'data': {
        'id': orderId,
        'orderNumber': '#UB-270926-001',
        'orderStatus': currentStatus,
        'total': 500.0,
        'createdAt': '2026-09-08T10:12:00.000Z',
        'items': [
          {
            'productName': 'Organic Hass Avocado',
            'unit': 'Pack of 2',
            'quantity': 2,
            'unitPrice': 240.0,
            'totalPrice': 480.0,
          },
          {
            'productName': 'Fresh Kale',
            'unit': '250g',
            'quantity': 1,
            'unitPrice': 20.0,
            'totalPrice': 20.0,
          },
          {
            'productName': 'Artisan Sourdough',
            'unit': '1 Loaf',
            'quantity': 1,
            'unitPrice': 320.0,
            'totalPrice': 320.0,
          },
        ],
        'address': {
          'type': 'Home',
          'receiverName': 'Maulik Patel',
          'phone': '+91 98765 43210',
          'addressLine': '123 Green Heights, Opp Central Park',
          'city': 'Ahmedabad',
          'pincode': '380001',
        },
      },
    };
  }

  @override
  Future<List<dynamic>> getOrders() async => [];
}

final _sampleOrderData = {
  'id': 'ord_123',
  'orderNumber': '#UB-270926-001',
  'orderStatus': 'PREPARING',
  'total': 500.0,
  'createdAt': '2026-09-08T10:12:00.000Z',
  'items': [
    {'productName': 'Organic Hass Avocado', 'quantity': 2},
    {'productName': 'Fresh Kale', 'quantity': 1},
    {'productName': 'Artisan Sourdough', 'quantity': 1},
  ],
  'address': {
    'type': 'Home',
    'receiverName': 'Maulik Patel',
    'addressLine': '123 Green Heights, Opp Central Park',
    'city': 'Ahmedabad',
  },
};

Widget _createTrackingTestWidget({
  String? orderId = 'ord_123',
  String? orderNumber = '#UB-270926-001',
  Map<String, dynamic>? initialOrderData,
  OrderRepository? mockRepo,
  GoRouter? customRouter,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final repo = mockRepo ?? MockOrderTrackingRepository();

  if (customRouter != null) {
    return ProviderScope(
      overrides: [
        orderRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        routerConfig: customRouter,
      ),
    );
  }

  return ProviderScope(
    overrides: [
      orderRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: OrderTrackingScreen(
        orderId: orderId,
        orderNumber: orderNumber,
        initialOrderData: initialOrderData,
      ),
    ),
  );
}

void main() {
  group('Screen 21 — Order Tracking Tests', () {
    testWidgets('1. Screen 20 navigates to Screen 21 on Track Order tap', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderTrackingRepository();
      final router = GoRouter(
        initialLocation: RouteNames.orderSuccess,
        routes: [
          GoRoute(
            path: RouteNames.orderSuccess,
            builder: (context, state) => OrderSuccessScreen(
              orderId: 'ord_123',
              orderData: {'order': _sampleOrderData},
            ),
          ),
          GoRoute(
            path: RouteNames.orderTracking,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return OrderTrackingScreen(
                orderId: extra?['orderId'] as String?,
                orderNumber: extra?['orderNumber'] as String?,
                initialOrderData: extra,
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(_createTrackingTestWidget(
        customRouter: router,
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      final trackButton = find.byKey(const Key('order_success_track_button'));
      expect(trackButton, findsOneWidget);
      await tester.tap(trackButton);
      await tester.pumpAndSettle();

      expect(find.byType(OrderTrackingScreen), findsOneWidget);
      expect(find.text('Track Order'), findsOneWidget);
    });

    testWidgets('2. Correct order ID and live badge are passed and displayed', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ORDER ID'), findsOneWidget);
      expect(find.text('#UB-270926-001'), findsOneWidget);
      expect(find.text('LIVE ORDER'), findsOneWidget);
    });

    testWidgets('3. Back button in AppHeader pops back or navigates to home', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: RouteNames.home,
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const Scaffold(body: Center(child: Text('Home Destination'))),
          ),
          GoRoute(
            path: RouteNames.orderTracking,
            builder: (context, state) => const OrderTrackingScreen(orderId: 'ord_123'),
          ),
        ],
      );

      await tester.pumpWidget(_createTrackingTestWidget(customRouter: router));
      await tester.pumpAndSettle();

      router.push(RouteNames.orderTracking);
      await tester.pumpAndSettle();

      expect(find.byType(OrderTrackingScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Home Destination'), findsOneWidget);
    });

    testWidgets('4. Successful order fetch renders all core sections', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.byType(TrackingHeroBanner), findsOneWidget);
      expect(find.byType(OrderProgressTimeline), findsOneWidget);
      expect(find.byType(OrderItemsDeliveryCard), findsOneWidget);
      expect(find.textContaining('Need help with this order?'), findsOneWidget);
    });

    testWidgets('5. Hero banner displays packing step, title, and arrival pill', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('CURRENT STEP: PACKING'), findsOneWidget);
      expect(find.text('Your Order is Being Prepared'), findsOneWidget);
      expect(find.textContaining('Fresh groceries are being carefully picked'), findsOneWidget);
      expect(find.text('ESTIMATED ARRIVAL TODAY • 8–15 MIN'), findsOneWidget);
    });

    testWidgets('6. Correct total amount is formatted with CurrencyFormatter', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('₹500'), findsOneWidget);
    });

    testWidgets('7. Correct item count is displayed in summary card', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Order Items (3 items)'), findsOneWidget);
    });

    testWidgets('8. Correct delivery address and recipient are displayed', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Delivering to Home:'), findsOneWidget);
      expect(find.textContaining('Maulik Patel, 123 Green Heights, Opp Central Park, Ahmedabad'), findsOneWidget);
    });

    testWidgets('9. Status Mapping: PLACED status maps to Order Placed and verifying step', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderTrackingRepository()..currentStatus = 'PLACED';
      await tester.pumpWidget(_createTrackingTestWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('CURRENT STEP: VERIFYING'), findsOneWidget);
      expect(find.text('Order Placed Successfully'), findsOneWidget);
    });

    testWidgets('10. Status Mapping: CONFIRMED status maps to Order Confirmed', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderTrackingRepository()..currentStatus = 'CONFIRMED';
      await tester.pumpWidget(_createTrackingTestWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('CURRENT STEP: CONFIRMED'), findsOneWidget);
      expect(find.text('Order Confirmed & Verified'), findsOneWidget);
    });

    testWidgets('11. Status Mapping: PREPARING status maps to Packing step with NOW badge', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderTrackingRepository()..currentStatus = 'PREPARING';
      await tester.pumpWidget(_createTrackingTestWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('CURRENT STEP: PACKING'), findsOneWidget);
      expect(find.text('NOW'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('12. Status Mapping: READY_FOR_PICKUP status maps to Ready for Pickup', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderTrackingRepository()..currentStatus = 'READY_FOR_PICKUP';
      await tester.pumpWidget(_createTrackingTestWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('CURRENT STEP: PICKUP'), findsOneWidget);
      expect(find.text('Order is Ready for Pickup'), findsOneWidget);
    });

    testWidgets('13. Status Mapping: PICKED_UP status maps to On The Way', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderTrackingRepository()..currentStatus = 'PICKED_UP';
      await tester.pumpWidget(_createTrackingTestWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('CURRENT STEP: ON THE WAY'), findsOneWidget);
      expect(find.text('Your Order is Out for Delivery'), findsOneWidget);
    });

    testWidgets('14. Status Mapping: OUT_FOR_DELIVERY status maps to Out for Delivery', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderTrackingRepository()..currentStatus = 'OUT_FOR_DELIVERY';
      await tester.pumpWidget(_createTrackingTestWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('CURRENT STEP: ON THE WAY'), findsOneWidget);
      expect(find.text('Your Order is Out for Delivery'), findsOneWidget);
    });

    testWidgets('15. Status Mapping: DELIVERED status maps to complete state', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderTrackingRepository()..currentStatus = 'DELIVERED';
      await tester.pumpWidget(_createTrackingTestWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('DELIVERY COMPLETE'), findsOneWidget);
      expect(find.text('Order Delivered Successfully'), findsOneWidget);
      expect(find.text('DELIVERED'), findsWidgets);
    });

    testWidgets('16. Status Mapping: CANCELLED status displays cancellation banner', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderTrackingRepository()..currentStatus = 'CANCELLED';
      await tester.pumpWidget(_createTrackingTestWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('ORDER CANCELLED'), findsOneWidget);
      expect(find.text('This Order Has Been Cancelled'), findsOneWidget);
      expect(find.textContaining('Order Cancelled. Progress has been discontinued.'), findsOneWidget);
    });

    testWidgets('17. Loading state without initial data displays CircularProgressIndicator', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget(
        orderId: 'ord_async_load',
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('18. Network error without fallback data displays retry card', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderTrackingRepository()..shouldFail = true;
      await tester.pumpWidget(_createTrackingTestWidget(
        orderId: 'ord_err',
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to Load Tracking'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('19. Order not found displays clean empty state', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderTrackingRepository()..returnNull = true;
      await tester.pumpWidget(_createTrackingTestWidget(
        orderId: 'ord_null',
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to Load Tracking'), findsOneWidget);
    });

    testWidgets('20. Missing order ID without initial data displays No Order Selected state', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget(
        orderId: '',
        initialOrderData: null,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Order Selected'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('21. View items tap triggers user notice', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget());
      await tester.pumpAndSettle();

      final viewItemsBtn = find.byKey(const Key('order_tracking_view_items_button'));
      expect(viewItemsBtn, findsOneWidget);
      await tester.ensureVisible(viewItemsBtn);
      await tester.tap(viewItemsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailsScreen), findsOneWidget);
      expect(find.text('Order Details'), findsOneWidget);
    });

    testWidgets('22. Contact support tap triggers support details notice', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget());
      await tester.pumpAndSettle();

      final supportBtn = find.byKey(const Key('order_tracking_support_button'));
      expect(supportBtn, findsOneWidget);
      await tester.ensureVisible(supportBtn);
      await tester.tap(supportBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Support: Please call'), findsOneWidget);
    });

    testWidgets('23. 320dp responsive layout renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Track Order'), findsOneWidget);
      expect(find.byType(TrackingHeroBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('24. 390dp responsive layout renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Track Order'), findsOneWidget);
      expect(find.byType(TrackingHeroBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('25. 430dp responsive layout renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(430 * 3, 932 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Track Order'), findsOneWidget);
      expect(find.byType(TrackingHeroBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('26. Dark theme renders cleanly', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTrackingTestWidget(
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Track Order'), findsOneWidget);
      expect(find.byType(OrderProgressTimeline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
