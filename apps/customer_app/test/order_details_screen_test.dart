import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/features/checkout/data/repositories/order_repository.dart';
import 'package:customer_app/features/checkout/presentation/providers/order_provider.dart';
import 'package:customer_app/features/orders/presentation/screens/order_details_screen.dart';
import 'package:customer_app/features/orders/presentation/screens/order_tracking_screen.dart';
import 'package:customer_app/features/orders/presentation/widgets/order_bill_summary_card.dart';
import 'package:customer_app/features/orders/presentation/widgets/order_item_card.dart';
import 'package:customer_app/shared/widgets/app_header.dart';

class MockOrderDetailsRepository implements OrderRepository {
  bool shouldFail = false;
  bool returnNull = false;
  String? failureMessage;
  Map<String, dynamic>? customResponse;

  @override
  Future<Map<String, dynamic>> createOrder({
    required String fulfillmentType,
    required String? addressId,
    required String? storeId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    return {};
  }

  @override
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    if (shouldFail) {
      throw Exception(failureMessage ?? 'NETWORK_ERROR');
    }
    if (returnNull) {
      return {'success': false, 'data': null};
    }
    if (customResponse != null) {
      return customResponse!;
    }
    return {
      'id': orderId,
      'orderNumber': '#UB-270926-001',
      'orderStatus': 'PLACED',
      'subtotal': 950.0,
      'deliveryFee': 30.0,
      'codCharge': 0.0,
      'discount': 0.0,
      'total': 980.0,
      'paymentMethod': 'ONLINE',
      'paymentStatus': 'PAID',
      'createdAt': '2026-09-08T17:36:00.000Z',
      'items': [
        {
          'id': 'item_1',
          'productId': 'prod_1',
          'productName': 'Fresh Local Kale',
          'unit': 'Organic • 1 Bunch',
          'quantity': 1,
          'unitPrice': 240.0,
          'totalPrice': 240.0,
        },
        {
          'id': 'item_2',
          'productId': 'prod_2',
          'productName': 'Organic Hass Avocado',
          'unit': 'Pack of 2',
          'quantity': 2,
          'unitPrice': 160.0,
          'totalPrice': 320.0,
        },
        {
          'id': 'item_3',
          'productId': 'prod_3',
          'productName': 'Artisan Sourdough',
          'unit': 'Fresh Baked • 1 Loaf',
          'quantity': 1,
          'unitPrice': 390.0,
          'totalPrice': 390.0,
        },
      ],
      'address': {
        'type': 'Home',
        'receiverName': 'Maulik Patel',
        'addressLine': '123 Green Heights, Opp Central Park',
        'city': 'Rajkot',
      },
    };
  }

  @override
  Future<List<dynamic>> getOrders() async => [];
}

Widget _createOrderDetailsTestWidget({
  String? orderId = 'ord_123',
  String? orderNumber = '#UB-270926-001',
  Map<String, dynamic>? initialOrderData,
  MockOrderDetailsRepository? mockRepo,
  GoRouter? customRouter,
}) {
  final repository = mockRepo ?? MockOrderDetailsRepository();

  if (customRouter != null) {
    return ProviderScope(
      overrides: [
        orderRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        routerConfig: customRouter,
      ),
    );
  }

  return ProviderScope(
    overrides: [
      orderRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      home: OrderDetailsScreen(
        orderId: orderId,
        orderNumber: orderNumber,
        initialOrderData: initialOrderData,
      ),
    ),
  );
}

void main() {
  group('Screen 22 — Order Details Comprehensive Tests', () {
    testWidgets('1. Screen renders correctly with AppHeader and title Order Details', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderDetailsTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.text('Order Details'), findsOneWidget);
      expect(find.byType(OrderBillSummaryCard), findsOneWidget);
      expect(find.byType(OrderItemCard), findsNWidgets(3));
    });

    testWidgets('2. Correct authoritative orderNumber is displayed', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderDetailsTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('#UB-270926-001'), findsOneWidget);
    });

    testWidgets('3. Correct order date and item count are displayed', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderDetailsTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('3 items'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
    });

    testWidgets('4. All order items render with product name, unit, and price', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderDetailsTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Fresh Local Kale'), findsOneWidget);
      expect(find.text('Organic • 1 Bunch'), findsOneWidget);
      expect(find.text('₹240'), findsOneWidget);

      expect(find.text('Organic Hass Avocado'), findsOneWidget);
      expect(find.text('Pack of 2'), findsOneWidget);
      expect(find.text('Qty: 2'), findsOneWidget);
      expect(find.text('₹320'), findsOneWidget);

      expect(find.text('Artisan Sourdough'), findsOneWidget);
      expect(find.text('Fresh Baked • 1 Loaf'), findsOneWidget);
      expect(find.text('₹390'), findsOneWidget);
    });

    testWidgets('5. Bill summary card displays Subtotal, Delivery Fee, and Grand Total', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderDetailsTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('₹950'), findsOneWidget);
      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('₹30'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('₹980'), findsOneWidget);
    });

    testWidgets('6. Free delivery renders FREE text in bill summary', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderDetailsRepository()
        ..customResponse = {
          'id': 'ord_free',
          'orderNumber': '#UB-270926-002',
          'subtotal': 1500.0,
          'deliveryFee': 0.0,
          'total': 1500.0,
          'items': [],
        };

      await tester.pumpWidget(_createOrderDetailsTestWidget(
        orderId: 'ord_free',
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('FREE'), findsOneWidget);
    });

    testWidgets('7. Discount and COD charges render when present in backend response', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderDetailsRepository()
        ..customResponse = {
          'id': 'ord_extra',
          'orderNumber': '#UB-270926-003',
          'subtotal': 1000.0,
          'deliveryFee': 30.0,
          'codCharge': 20.0,
          'discount': 50.0,
          'total': 1000.0,
          'paymentMethod': 'COD',
          'items': [],
        };

      await tester.pumpWidget(_createOrderDetailsTestWidget(
        orderId: 'ord_extra',
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cash Handling Fee'), findsOneWidget);
      expect(find.text('₹20'), findsOneWidget);
      expect(find.text('Discount'), findsOneWidget);
      expect(find.text('-₹50'), findsOneWidget);
      expect(find.text('Paid via Cash on Delivery'), findsOneWidget);
    });

    testWidgets('8. Payment method and historical delivery address render correctly', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderDetailsTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Paid via ONLINE'), findsOneWidget);
      expect(find.textContaining('Home • Maulik Patel — 123 Green Heights'), findsOneWidget);
    });

    testWidgets('9. Loading state displays cleanly', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderDetailsTestWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading order details...'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('10. Error state displays retry button on network failure', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderDetailsRepository()..shouldFail = true;
      await tester.pumpWidget(_createOrderDetailsTestWidget(
        orderId: 'ord_err',
        mockRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to Load Order Details'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry
      mockRepo.shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('#UB-270926-001'), findsOneWidget);
    });

    testWidgets('11. Empty / missing order ID displays No Order Selected state', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createOrderDetailsTestWidget(
        orderId: '',
        initialOrderData: null,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Order Selected'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('12. Screen 21 View items navigates cleanly to Screen 22 (Order Details)', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: RouteNames.orderTracking,
        routes: [
          GoRoute(
            path: RouteNames.orderTracking,
            builder: (context, state) => const OrderTrackingScreen(
              orderId: 'ord_track_123',
              orderNumber: '#UB-270926-001',
            ),
          ),
          GoRoute(
            path: RouteNames.orderDetails,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return OrderDetailsScreen(
                orderId: extra?['orderId'] as String?,
                orderNumber: extra?['orderNumber'] as String?,
                initialOrderData: extra,
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(_createOrderDetailsTestWidget(customRouter: router));
      await tester.pumpAndSettle();

      final viewItemsBtn = find.byKey(const Key('order_tracking_view_items_button'));
      expect(viewItemsBtn, findsOneWidget);

      await tester.ensureVisible(viewItemsBtn);
      await tester.tap(viewItemsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailsScreen), findsOneWidget);
      expect(find.text('#UB-270926-001'), findsOneWidget);
    });

    testWidgets('13. Dark theme renders correctly without crash', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(MockOrderDetailsRepository()),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const OrderDetailsScreen(
              orderId: 'ord_123',
              orderNumber: '#UB-270926-001',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailsScreen), findsOneWidget);
      expect(find.text('#UB-270926-001'), findsOneWidget);
    });

    testWidgets('14. Responsive viewport checks (320dp, 360dp, 390dp, 412dp, 430dp)', (tester) async {
      final widths = [320.0, 360.0, 390.0, 412.0, 430.0];

      for (final width in widths) {
        tester.view.physicalSize = Size(width * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(_createOrderDetailsTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(OrderDetailsScreen), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Failed at width $width');
      }
      tester.view.resetPhysicalSize();
    });
  });
}
