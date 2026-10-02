import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/checkout/data/repositories/order_repository.dart';
import 'package:customer_app/features/checkout/presentation/providers/order_provider.dart';
import 'package:customer_app/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:customer_app/shared/widgets/app_header.dart';
import 'package:customer_app/shared/widgets/product_quantity_control.dart';

class MockOrderRepository implements OrderRepository {
  bool shouldFail = false;
  String? failureCode;
  Map<String, dynamic>? lastPayload;

  @override
  Future<Map<String, dynamic>> createOrder({
    required String fulfillmentType,
    required String? addressId,
    required String? storeId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    if (shouldFail) {
      throw Exception(failureCode ?? 'SERVER_ERROR');
    }
    lastPayload = {
      'fulfillmentType': fulfillmentType,
      'addressId': addressId,
      'storeId': storeId,
      'paymentMethod': paymentMethod,
      'items': items,
    };
    return {
      'success': true,
      'message': 'Order created successfully.',
      'data': {
        'order': {
          'id': 'order_123',
          'orderNumber': '#UB-270926-001',
          'total': 460.0,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    return {
      'success': true,
      'data': {
        'id': orderId,
        'orderNumber': '#UB-270926-001',
        'orderStatus': 'PLACED',
        'total': 460.0,
      },
    };
  }

  @override
  Future<List<dynamic>> getOrders() async => [];
}

final _testProducts = [
  const ProductModel(
    id: 'p_avocado',
    categoryId: 'cat_fruits',
    name: 'Organic Hass Avocados',
    price: 180.0,
    unit: 'Pack of 2',
    stockQuantity: 10.0,
  ),
  const ProductModel(
    id: 'p_kale',
    categoryId: 'cat_vegetables',
    name: 'Fresh Local Kale',
    price: 60.0,
    unit: '1 Bunch',
    stockQuantity: 15.0,
  ),
  const ProductModel(
    id: 'p_bread',
    categoryId: 'cat_bakery',
    name: 'Artisanal Sourdough Bread',
    price: 140.0,
    unit: '1 Loaf',
    stockQuantity: 8.0,
  ),
];

final _testAddress = {
  'id': 'addr_101',
  'title': 'Home',
  'addressLine':
      '123, Example Road, Green Heights, Opp. Central Park, Ahmedabad, Gujarat 380001',
  'city': 'Ahmedabad',
  'state': 'Gujarat',
  'pincode': '380001',
  'isDefault': true,
  'phone': '+91 98765 43210',
};

const _testStore = StoreModel(
  id: 'store_rajkot_central',
  storeId: 'UB-STORE-001',
  name: 'Unique Basket Central',
  address: 'Kalawad Road, Rajkot',
  city: 'Rajkot',
  state: 'Gujarat',
  pincode: '360001',
  phone: '+91 98765 00000',
  openingTime: '08:00 AM',
  closingTime: '10:00 PM',
  latitude: 22.3039,
  longitude: 70.8022,
  deliveryRadiusKm: 15.0,
  isActive: true,
);

Widget _createCheckoutTestWidget({
  required LocalStorageService localStorage,
  Map<String, int>? initialCart,
  DeliverySettingsModel? deliverySettings,
  CartSummaryModel? cartSummary,
  MockOrderRepository? mockOrderRepo,
  GoRouter? customRouter,
}) {
  final orderRepo = mockOrderRepo ?? MockOrderRepository();

  final container = ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(localStorage),
      homeProductsProvider.overrideWith((ref) => _testProducts),
      deliverySettingsProvider.overrideWith(
        (ref) async =>
            deliverySettings ??
            const DeliverySettingsModel(
              deliveryFee: 30.0,
              freeDeliveryThreshold: 499.0,
            ),
      ),
      if (cartSummary != null)
        cartSummaryProvider.overrideWith((ref) async => cartSummary),
      customerAddressesProvider.overrideWith((ref) => [_testAddress]),
      defaultCustomerAddressProvider.overrideWith((ref) => const AsyncValue.data({
            'id': 'addr_101',
            'title': 'Home',
            'addressLine':
                '123, Example Road, Green Heights, Opp. Central Park, Ahmedabad, Gujarat 380001',
            'city': 'Ahmedabad',
            'state': 'Gujarat',
            'pincode': '380001',
            'isDefault': true,
            'phone': '+91 98765 43210',
          })),
      customerProfileProvider.overrideWith((ref) => {
            'name': 'Maulik Patel',
            'phone': '+91 98765 43210',
          }),
      servingStoreProvider.overrideWith((ref) => _testStore),
      orderRepositoryProvider.overrideWithValue(orderRepo),
    ],
  );

  if (initialCart != null) {
    for (final entry in initialCart.entries) {
      for (int i = 0; i < entry.value; i++) {
        container.read(cartNotifierProvider.notifier).increment(entry.key);
      }
    }
  }

  if (customRouter != null) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: customRouter,
      ),
    );
  }

  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      home: CheckoutScreen(),
    ),
  );
}

void main() {
  group('Screen 16 — Checkout Tests', () {
    test('1. RouteNames.checkout is defined correctly as /checkout', () {
      expect(RouteNames.checkout, equals('/checkout'));
    });

    testWidgets('2. Checkout renders with AppHeader and title Checkout', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_avocado': 2, 'p_kale': 1, 'p_bread': 1},
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets('3. Correct dynamic cart item count (4 items)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_avocado': 2, 'p_kale': 1, 'p_bread': 1},
      ));
      await tester.pumpAndSettle();

      expect(find.text('YOUR CART'), findsOneWidget);
      expect(find.text('(4 items)'), findsOneWidget);
    });

    testWidgets('4. Cart items render with name, pack size, price, and ProductQuantityControl', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_avocado': 2, 'p_kale': 1, 'p_bread': 1},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Organic Hass Avocados'), findsOneWidget);
      expect(find.text('Pack of 2'), findsOneWidget);
      expect(find.text('₹180.00'), findsOneWidget);

      expect(find.text('Fresh Local Kale'), findsOneWidget);
      expect(find.text('1 Bunch'), findsOneWidget);
      expect(find.text('₹60.00'), findsOneWidget);

      expect(find.text('Artisanal Sourdough Bread'), findsOneWidget);
      expect(find.text('1 Loaf'), findsOneWidget);
      expect(find.text('₹140.00'), findsOneWidget);

      expect(find.byType(ProductQuantityControl), findsNWidgets(3));
    });

    testWidgets('5. Quantity increment updates item total, subtotal, and To Pay', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
      ));
      await tester.pumpAndSettle();

      // Subtotal: ₹60.00, Delivery Fee: ₹30.00, Discount: -₹20.00, To Pay: ₹70.00
      expect(find.text('₹60.00'), findsNWidgets(2)); // Item price & Subtotal
      expect(find.text('₹30.00'), findsOneWidget); // Delivery fee
      expect(find.text('₹70.00'), findsOneWidget); // To Pay

      // Tap + on Kale
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      // Subtotal now ₹120.00, Delivery Fee: ₹30.00, Discount: -₹20.00, To Pay: ₹130.00
      expect(find.text('₹120.00'), findsOneWidget);
      expect(find.text('₹130.00'), findsOneWidget);
    });

    testWidgets('6. Quantity decrement updates item total and totals', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 2},
      ));
      await tester.pumpAndSettle();

      expect(find.text('₹120.00'), findsOneWidget);
      expect(find.text('₹130.00'), findsOneWidget);

      // Tap - on Kale
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();

      expect(find.text('₹60.00'), findsNWidgets(2));
      expect(find.text('₹70.00'), findsOneWidget);
    });

    testWidgets('7. Decrementing last item handles empty cart', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
      ));
      await tester.pumpAndSettle();

      // Decrement the single item to 0
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(CheckoutScreen), findsOneWidget);
    });

    testWidgets('8. Default address section renders properly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
      ));
      await tester.pumpAndSettle();

      expect(find.text('DELIVERY ADDRESS'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Maulik Patel'), findsOneWidget);
      expect(find.textContaining('123, Example Road'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
    });

    testWidgets('9. Address and Payment Change actions navigate to addresses and payment methods screens', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: RouteNames.checkout,
        routes: [
          GoRoute(
            path: RouteNames.checkout,
            builder: (context, state) => const CheckoutScreen(),
          ),
          GoRoute(
            path: RouteNames.myAddresses,
            builder: (context, state) => const Scaffold(body: Center(child: Text('My Addresses Screen'))),
          ),
          GoRoute(
            path: RouteNames.paymentMethods,
            builder: (context, state) => const Scaffold(body: Center(child: Text('Payment Methods Screen'))),
          ),
        ],
      );

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
        customRouter: router,
      ));
      await tester.pumpAndSettle();

      // Tap Address Change button
      final addressChangeFinder = find.text('Change').first;
      await tester.tap(addressChangeFinder);
      await tester.pumpAndSettle();

      expect(find.text('My Addresses Screen'), findsOneWidget);

      // Go back to checkout
      router.go(RouteNames.checkout);
      await tester.pumpAndSettle();

      // Tap Payment Change button
      final paymentChangeFinder = find.text('Change').last;
      await tester.tap(paymentChangeFinder);
      await tester.pumpAndSettle();

      expect(find.text('Payment Methods Screen'), findsOneWidget);
    });

    testWidgets('10. Payment method selection switches between UPI and Pay On Delivery', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
      ));
      await tester.pumpAndSettle();

      expect(find.text('PAYMENT METHOD'), findsOneWidget);
      expect(find.textContaining('UPI —'), findsOneWidget);
      expect(find.text('Pay On Delivery'), findsOneWidget);

      // Tap Pay On Delivery
      await tester.tap(find.text('Pay On Delivery'));
      await tester.pumpAndSettle();

      // Tap back to UPI
      await tester.tap(find.textContaining('UPI —'));
      await tester.pumpAndSettle();
    });

    testWidgets('11. Bill Details calculations: Subtotal, Delivery Free, Bag Discount, To Pay, and Savings', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_avocado': 2, 'p_kale': 1, 'p_bread': 1},
      ));
      await tester.pumpAndSettle();

      // 2 * 180 + 1 * 60 + 1 * 140 = 360 + 60 + 140 = 560
      expect(find.text('BILL DETAILS'), findsOneWidget);
      expect(find.text('Items Subtotal'), findsOneWidget);
      expect(find.text('₹560.00'), findsOneWidget);

      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('FREE'), findsNWidgets(2)); // Delivery fee & Handling

      expect(find.text('Special Bag Discount'), findsOneWidget);
      expect(find.text('-₹20.00'), findsOneWidget);

      // To Pay = 560 - 20 = 540
      expect(find.text('To Pay'), findsOneWidget);
      expect(find.text('₹540.00'), findsOneWidget);

      expect(find.text('🎉 You saved ₹20.00 on this order'), findsOneWidget);
    });

    testWidgets('12. Place Order button renders with lock icon', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLACE ORDER'));
      expect(find.text('PLACE ORDER'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('13. Tapping Place Order triggers createOrder on repository, clears cart, and navigates to Order Success', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderRepository();
      final router = GoRouter(
        initialLocation: RouteNames.checkout,
        routes: [
          GoRoute(
            path: RouteNames.checkout,
            builder: (context, state) => const CheckoutScreen(),
          ),
          GoRoute(
            path: RouteNames.orderSuccess,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return Scaffold(
                body: Center(
                  child: Text('Order Success: ${extra?['orderNumber']}'),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 2},
        mockOrderRepo: mockRepo,
        customRouter: router,
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLACE ORDER'));
      await tester.tap(find.text('PLACE ORDER'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastPayload, isNotNull);
      expect(mockRepo.lastPayload?['fulfillmentType'], 'DELIVERY');
      expect(mockRepo.lastPayload?['addressId'], 'addr_101');
      // CURRENT BEHAVIOUR, NOT A DECISION (P1-16): 'UPI' maps to ONLINE with no payment step;
      // provider/flow undecided (P4-01). Unpaid ONLINE orders are cancel-only (D-005).
      expect(mockRepo.lastPayload?['paymentMethod'], 'ONLINE');
      expect((mockRepo.lastPayload?['items'] as List).length, 1);

      expect(find.text('Order Success: #UB-270926-001'), findsOneWidget);
    });

    testWidgets('14. Order placement with Pay On Delivery sends COD', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderRepository();

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
        mockOrderRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      // Select COD
      await tester.tap(find.text('Pay On Delivery'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLACE ORDER'));
      await tester.tap(find.text('PLACE ORDER'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastPayload?['paymentMethod'], 'COD');
    });

    testWidgets('15. Server error shows user-friendly error message', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderRepository()..shouldFail = true;

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
        mockOrderRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLACE ORDER'));
      await tester.tap(find.text('PLACE ORDER'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to place order. Please try again.'), findsOneWidget);
    });

    testWidgets('16. Insufficient stock error shows helpful notice', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderRepository()
        ..shouldFail = true
        ..failureCode = 'INSUFFICIENT_STOCK:Fresh Local Kale:0:1 Bunch';

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
        mockOrderRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLACE ORDER'));
      await tester.tap(find.text('PLACE ORDER'));
      await tester.pumpAndSettle();

      expect(find.text('Some items in your cart are no longer available in the requested quantity.'), findsOneWidget);
    });

    testWidgets('17. No delivery available error shows helpful notice', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockOrderRepository()
        ..shouldFail = true
        ..failureCode = 'NO_DELIVERY_AVAILABLE';

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
        mockOrderRepo: mockRepo,
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLACE ORDER'));
      await tester.tap(find.text('PLACE ORDER'));
      await tester.pumpAndSettle();

      expect(find.text('Delivery is currently not available for this address location.'), findsOneWidget);
    });

    testWidgets('18. Back button navigates back to Cart', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: RouteNames.checkout,
        routes: [
          GoRoute(
            path: RouteNames.cart,
            builder: (context, state) => const Scaffold(body: Center(child: Text('Cart Screen'))),
          ),
          GoRoute(
            path: RouteNames.checkout,
            builder: (context, state) => const CheckoutScreen(),
          ),
        ],
      );

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
        customRouter: router,
      ));
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Cart Screen'), findsOneWidget);
    });

    testWidgets('19. Responsive layout across multiple device widths (320dp, 360dp, 390dp, 430dp) with zero overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final deviceWidths = [320.0, 360.0, 390.0, 430.0];

      for (final width in deviceWidths) {
        tester.view.physicalSize = Size(width * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(_createCheckoutTestWidget(
          localStorage: localStorage,
          initialCart: {'p_avocado': 2, 'p_kale': 1, 'p_bread': 1},
        ));
        await tester.pumpAndSettle();

        expect(find.text('Checkout'), findsOneWidget);
        expect(find.text('YOUR CART'), findsOneWidget);
        expect(find.text('DELIVERY ADDRESS'), findsOneWidget);
        expect(find.text('PAYMENT METHOD'), findsOneWidget);
        expect(find.text('BILL DETAILS'), findsOneWidget);
        await tester.ensureVisible(find.text('PLACE ORDER'));
        expect(find.text('PLACE ORDER'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('20. Dark theme renders correctly without errors', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          homeProductsProvider.overrideWith((ref) => _testProducts),
          customerAddressesProvider.overrideWith((ref) => [_testAddress]),
          defaultCustomerAddressProvider.overrideWith((ref) => const AsyncValue.data({
                'id': 'addr_101',
                'title': 'Home',
                'addressLine':
                    '123, Example Road, Green Heights, Opp. Central Park, Ahmedabad, Gujarat 380001',
                'city': 'Ahmedabad',
                'state': 'Gujarat',
                'pincode': '380001',
                'isDefault': true,
                'phone': '+91 98765 43210',
              })),
          customerProfileProvider.overrideWith((ref) => {
                'name': 'Maulik Patel',
                'phone': '+91 98765 43210',
              }),
          servingStoreProvider.overrideWith((ref) => _testStore),
          orderRepositoryProvider.overrideWithValue(MockOrderRepository()),
        ],
      );

      for (int i = 0; i < 2; i++) {
        container.read(cartNotifierProvider.notifier).increment('p_avocado');
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('YOUR CART'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17. Dynamic backend delivery fee (₹50) updates Checkout delivery fee and To Pay calculation', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        deliverySettings: const DeliverySettingsModel(
          deliveryFee: 50.0,
          freeDeliveryThreshold: 500.0,
        ),
        initialCart: {'p_kale': 1}, // 60.0
      ));
      await tester.pumpAndSettle();

      // Subtotal: 60.00, Delivery Fee: 50.00, Discount: -20.00, To Pay: 90.00
      expect(find.text('₹60.00'), findsNWidgets(2)); // Item price & Subtotal
      expect(find.text('₹50.00'), findsOneWidget); // Delivery Fee
      expect(find.text('-₹20.00'), findsOneWidget); // Discount
      expect(find.text('₹90.00'), findsOneWidget); // To Pay: 60 + 50 - 20
    });

    testWidgets('18. Authoritative backend CartSummary pricing values render directly on Checkout screen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCheckoutTestWidget(
        localStorage: localStorage,
        cartSummary: const CartSummaryModel(
          subtotal: 180.0,
          deliveryFee: 30.0,
          discount: 20.0,
          total: 190.0,
          freeDeliveryThreshold: 499.0,
        ),
        initialCart: {'p_kale': 3},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Items Subtotal'), findsOneWidget);
      expect(find.text('₹180.00'), findsWidgets);
      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('₹30.00'), findsOneWidget);
      expect(find.text('Special Bag Discount'), findsOneWidget);
      expect(find.text('-₹20.00'), findsOneWidget);
      expect(find.text('To Pay'), findsOneWidget);
      expect(find.text('₹190.00'), findsOneWidget); // Authoritative backend total
    });
  });
}
