import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/features/checkout/data/repositories/order_repository.dart';
import 'package:customer_app/features/checkout/presentation/providers/order_provider.dart';
import 'package:customer_app/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:customer_app/features/orders/presentation/screens/order_details_screen.dart';
import 'package:customer_app/features/orders/presentation/screens/order_tracking_screen.dart';
import 'package:customer_app/features/orders/presentation/widgets/my_orders_help_card.dart';
import 'package:customer_app/features/orders/presentation/widgets/order_history_card.dart';
import 'package:customer_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:customer_app/shared/widgets/app_header.dart';
import 'package:customer_app/shared/widgets/app_loading.dart';
import 'package:customer_app/shared/widgets/app_error_state.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMyOrdersRepository implements OrderRepository {
  bool shouldThrow = false;
  List<dynamic> ordersToReturn = [];
  int getOrdersCallCount = 0;

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
    return {
      'id': orderId,
      'orderNumber': '#UB-270926-001',
      'orderStatus': 'PLACED',
      'total': 684.0,
      'items': [],
    };
  }

  @override
  Future<List<dynamic>> getOrders() async {
    getOrdersCallCount++;
    if (shouldThrow) {
      throw Exception('FAILED_FETCH_ORDERS');
    }
    return ordersToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMyOrdersRepository mockOrderRepo;

  final sampleOrders = [
    {
      'id': 'order_1',
      'orderNumber': '#UB10482',
      'orderStatus': 'PREPARING',
      'total': 684.0,
      'createdAt': '2026-09-29T18:42:00.000Z',
      'items': [
        {'productName': 'Tomatoes', 'quantity': 1},
        {'productName': 'Bananas', 'quantity': 1},
        {'productName': 'Milk', 'quantity': 1},
        {'productName': 'Bread', 'quantity': 1},
      ],
    },
    {
      'id': 'order_2',
      'orderNumber': '#UB10471',
      'orderStatus': 'OUT_FOR_DELIVERY',
      'total': 1245.0,
      'createdAt': '2026-09-28T19:18:00.000Z',
      'items': [
        {'productName': 'Organic Avocados', 'quantity': 2},
        {'productName': 'Bread', 'quantity': 1},
        {'productName': 'Eggs', 'quantity': 1},
        {'productName': 'Butter', 'quantity': 1},
        {'productName': 'Cheese', 'quantity': 1},
      ],
    },
    {
      'id': 'order_3',
      'orderNumber': '#UB10398',
      'orderStatus': 'DELIVERED',
      'total': 532.0,
      'createdAt': '2026-09-08T17:36:00.000Z',
      'items': [
        {'productName': 'Royal Gala Apples', 'quantity': 1},
        {'productName': 'Milk', 'quantity': 1},
        {'productName': 'Carrots', 'quantity': 1},
        {'productName': 'Spinach', 'quantity': 1},
      ],
    },
    {
      'id': 'order_4',
      'orderNumber': '#UB10312',
      'orderStatus': 'DELIVERED',
      'total': 285.0,
      'createdAt': '2026-09-02T11:20:00.000Z',
      'items': [
        {'productName': 'Crisp Salad Mix', 'quantity': 1},
        {'productName': 'Greek Yogurt', 'quantity': 1},
      ],
    },
    {
      'id': 'order_5',
      'orderNumber': '#UB10290',
      'orderStatus': 'CANCELLED',
      'total': 150.0,
      'createdAt': '2026-08-25T14:10:00.000Z',
      'items': [
        {'productName': 'Watermelon', 'quantity': 1},
      ],
    },
  ];

  setUp(() {
    mockOrderRepo = MockMyOrdersRepository();
    mockOrderRepo.ordersToReturn = sampleOrders;
  });

  Widget createScreenHarness({
    List<dynamic>? ordersOverride,
    bool throwError = false,
  }) {
    if (throwError) {
      mockOrderRepo.shouldThrow = true;
    } else if (ordersOverride != null) {
      mockOrderRepo.ordersToReturn = ordersOverride;
    }

    return ProviderScope(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        customerOrdersProvider.overrideWith((ref) async {
          if (throwError) throw Exception('NETWORK_ERROR');
          return ordersOverride ?? sampleOrders;
        }),
      ],
      child: const MaterialApp(
        home: MyOrdersScreen(),
      ),
    );
  }

  group('Screen 27 — My Orders Unit & Widget Tests', () {
    testWidgets('1. Screen renders AppHeader with title My Orders and back button', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('2. Populated list renders multiple order cards with correct order numbers', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byType(OrderHistoryCard), findsWidgets);
      expect(find.text('#UB10482'), findsOneWidget);
      expect(find.text('#UB10471'), findsOneWidget);
      expect(find.text('#UB10398'), findsOneWidget);
    });

    testWidgets('3. Order cards display formatted currency total amounts', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('₹684'), findsOneWidget);
      expect(find.text('₹1,245'), findsOneWidget);
      expect(find.text('₹532'), findsOneWidget);
    });

    testWidgets('4. Order status badges render appropriate labels and indicators', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('Preparing'), findsOneWidget);
      expect(find.text('Out for Delivery'), findsOneWidget);
      expect(find.text('Delivered'), findsWidgets);
    });

    testWidgets('5. Item summary preview derives items and counts correctly', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      // Order 1: 4 items -> first 3 + 1 more
      expect(find.text('4 items • Tomatoes, Bananas, Milk + 1 more'), findsOneWidget);

      // Order 2: 5 items -> first 3 + 2 more
      expect(find.text('5 items • Organic Avocados, Bread, Eggs + 2 more'), findsOneWidget);
    });

    testWidgets('6. Active orders show Track Order CTA button', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('Track Order'), findsWidgets);
    });

    testWidgets('7. Completed & Cancelled orders show View Details CTA button', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('View Details'), findsWidgets);
    });

    testWidgets('8. Bottom support card renders with Help action button', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.byType(MyOrdersHelpCard), findsOneWidget);
      expect(find.text('Need help with an order?'), findsOneWidget);
      expect(find.text('Chat with our customer support team'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);

      await tester.tap(find.text('Help'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Support: Please call'), findsOneWidget);
    });

    testWidgets('9. Footer displays total order count note', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Showing 5 orders'), findsOneWidget);
    });

    testWidgets('10. Empty orders state displays Screen 28 layout with illustration, caption, and Start Shopping CTA', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness(ordersOverride: []));
      await tester.pumpAndSettle();

      expect(find.text('No orders yet'), findsOneWidget);
      expect(find.textContaining('You haven\'t placed any orders yet'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);
      expect(find.text('Fresh Fruits & Vegetables, delivered to your doorstep.'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.byType(OrderHistoryCard), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10b. Empty orders Start Shopping button navigates to Home', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: RouteNames.myOrders,
        routes: [
          GoRoute(
            path: RouteNames.myOrders,
            builder: (context, state) => const MyOrdersScreen(),
          ),
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const Scaffold(
              body: Text('HOME_SCREEN_CATALOG'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepo),
            customerOrdersProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start Shopping'), findsOneWidget);
      await tester.tap(find.text('Start Shopping'));
      await tester.pumpAndSettle();

      expect(find.text('HOME_SCREEN_CATALOG'), findsOneWidget);
    });

    testWidgets('10c. Loading state shows AppLoading and hides empty state', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final completer = Completer<List<dynamic>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepo),
            customerOrdersProvider.overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            home: MyOrdersScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppLoading), findsOneWidget);
      expect(find.text('No orders yet'), findsNothing);

      // Complete future to clean up pending futures
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('11. Error state displays retry button on network failure', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness(throwError: true));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Unable to load orders'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('12. Track Order navigation pushes RouteNames.orderTracking', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: RouteNames.myOrders,
        routes: [
          GoRoute(
            path: RouteNames.myOrders,
            builder: (context, state) => const MyOrdersScreen(),
          ),
          GoRoute(
            path: RouteNames.orderTracking,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return Scaffold(
                body: Text('TRACKING: ${extra?['orderNumber']}'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepo),
            customerOrdersProvider.overrideWith((ref) async => sampleOrders),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on first Track Order button
      final trackOrderBtn = find.text('Track Order').first;
      await tester.tap(trackOrderBtn);
      await tester.pumpAndSettle();

      expect(find.text('TRACKING: #UB10482'), findsOneWidget);
    });

    testWidgets('13. View Details navigation pushes RouteNames.orderDetails', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: RouteNames.myOrders,
        routes: [
          GoRoute(
            path: RouteNames.myOrders,
            builder: (context, state) => const MyOrdersScreen(),
          ),
          GoRoute(
            path: RouteNames.orderDetails,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return Scaffold(
                body: Text('DETAILS: ${extra?['orderNumber']}'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepo),
            customerOrdersProvider.overrideWith((ref) async => sampleOrders),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on first View Details button
      final viewDetailsBtn = find.text('View Details').first;
      await tester.tap(viewDetailsBtn);
      await tester.pumpAndSettle();

      expect(find.text('DETAILS: #UB10398'), findsOneWidget);
    });

    testWidgets('14. Screen 25 Profile "My Orders" row navigates to Screen 27', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: RouteNames.profile,
        routes: [
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: RouteNames.myOrders,
            builder: (context, state) => const MyOrdersScreen(),
          ),
        ],
      );

      SharedPreferences.setMockInitialValues({
        'user_data': '{"name":"Maulik Patel","phone":"+91 98765 43210"}',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(storage),
            customerProfileProvider.overrideWith((ref) async => {
              'name': 'Maulik Patel',
              'phone': '+91 98765 43210',
            }),
            orderRepositoryProvider.overrideWithValue(mockOrderRepo),
            customerOrdersProvider.overrideWith((ref) async => sampleOrders),
            customerOrdersCountProvider.overrideWith((ref) => 5),
            favoritesNotifierProvider.overrideWith((ref) => FavoritesNotifier()),
            customerAddressesProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Orders'), findsOneWidget);
      await tester.tap(find.text('My Orders'));
      await tester.pumpAndSettle();

      expect(find.byType(MyOrdersScreen), findsOneWidget);
      expect(find.text('#UB10482'), findsOneWidget);
    });

    testWidgets('15. Responsive viewports render cleanly without overflow', (tester) async {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(createScreenHarness());
        await tester.pumpAndSettle();

        expect(find.text('My Orders'), findsOneWidget);
        expect(find.text('#UB10482'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('16. Dark mode renders correctly with proper contrast', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepo),
            customerOrdersProvider.overrideWith((ref) async => sampleOrders),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const MyOrdersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('#UB10482'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
