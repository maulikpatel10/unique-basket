import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/cart/data/repositories/cart_repository.dart';
import 'package:customer_app/features/checkout/data/repositories/order_repository.dart';
import 'package:customer_app/features/checkout/presentation/providers/order_provider.dart';
import 'package:customer_app/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';

/// P1-18: checkout reconciles with the server cart (backend is authoritative).
class _TokenStorage implements SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'access';
  @override
  Future<String?> getRefreshToken() async => 'refresh';
  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {}
  @override
  Future<void> clearTokens() async {}
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> clearAll() async {}
}

class _ServerCart implements CartRepository {
  final Map<String, double> server;
  int getCartCalls = 0;
  int summaryCalls = 0;
  int writes = 0;
  _ServerCart(this.server);

  List<CartItemModel> get _items => server.entries
      .map((e) => CartItemModel(id: 'ci_${e.key}', productId: e.key, price: 60, quantity: e.value, totalPrice: 60.0 * e.value))
      .toList();

  @override
  Future<List<CartItemModel>> getCart() async {
    getCartCalls++;
    return _items;
  }

  @override
  Future<CartSummaryModel> getCartSummary() async {
    summaryCalls++;
    return CartSummaryModel(items: _items);
  }

  @override
  Future<DeliverySettingsModel> getDeliverySettings() async => const DeliverySettingsModel();

  @override
  Future<Map<String, dynamic>> addItem({required String productId, required double quantity}) async {
    writes++;
    server[productId] = quantity;
    return {'id': 'ci_$productId'};
  }

  @override
  Future<Map<String, dynamic>> updateItem({required String cartItemId, required double quantity}) async {
    writes++;
    server[cartItemId.replaceFirst('ci_', '')] = quantity;
    return {};
  }

  @override
  Future<bool> removeItem(String cartItemId) async {
    writes++;
    server.remove(cartItemId.replaceFirst('ci_', ''));
    return true;
  }
}

class _OrderRepo implements OrderRepository {
  final _ServerCart cart;
  String? failureCode;
  List<Map<String, dynamic>>? lastItems;
  _OrderRepo(this.cart, {this.failureCode});

  @override
  Future<Map<String, dynamic>> createOrder({
    required String fulfillmentType,
    required String? addressId,
    required String? storeId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    lastItems = items;
    if (failureCode != null) throw Exception(failureCode);
    // The backend empties the cart in the order transaction.
    cart.server.clear();
    return {
      'data': {
        'order': {'id': 'o1', 'orderNumber': '#UB-031026-001', 'total': 120.0},
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getOrderById(String orderId) async => {};

  @override
  Future<List<dynamic>> getOrders() async => [];
}

const _store = StoreModel(
  id: 'store_1',
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

final _address = {
  'id': 'addr_101',
  'title': 'Home',
  'addressLine': '123, Example Road, Ahmedabad, Gujarat 380001',
  'city': 'Ahmedabad',
  'state': 'Gujarat',
  'pincode': '380001',
  'isDefault': true,
  'phone': '+91 98765 43210',
};

void main() {
  const kale = ProductModel(id: 'p_kale', categoryId: 'c', name: 'Fresh Local Kale', price: 60.0, unit: '1 Bunch', stockQuantity: 15.0);

  Future<ProviderContainer> pumpCheckout(
    WidgetTester tester,
    _ServerCart cart,
    _OrderRepo orders, {
    List<ProductModel> products = const [kale],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final localStorage = LocalStorageService(await SharedPreferences.getInstance());

    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        secureStorageProvider.overrideWithValue(_TokenStorage()),
        cartRepositoryProvider.overrideWithValue(cart),
        homeProductsProvider.overrideWith((ref) => products),
        deliverySettingsProvider.overrideWith((ref) async => const DeliverySettingsModel()),
        customerAddressesProvider.overrideWith((ref) => [_address]),
        defaultCustomerAddressProvider.overrideWith((ref) => AsyncValue.data(_address)),
        customerProfileProvider.overrideWith((ref) => {'name': 'Test', 'phone': '+91 98765 43210'}),
        servingStoreProvider.overrideWith((ref) => _store),
        orderRepositoryProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RouteNames.checkout,
      routes: [
        GoRoute(path: RouteNames.cart, builder: (_, __) => const Text('CART SCREEN')),
        GoRoute(path: RouteNames.checkout, builder: (_, __) => const CheckoutScreen()),
        GoRoute(path: RouteNames.orderSuccess, builder: (_, __) => const Text('ORDER SUCCESS')),
      ],
    );

    await container.read(cartNotifierProvider.notifier).loadCart();
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> placeOrder(WidgetTester tester) async {
    await tester.ensureVisible(find.text('PLACE ORDER'));
    await tester.tap(find.text('PLACE ORDER'));
    await tester.pumpAndSettle();
  }

  testWidgets('a rejected order reloads the cart and bill from the server', (tester) async {
    final cart = _ServerCart({'p_kale': 3});
    final orders = _OrderRepo(cart, failureCode: 'INSUFFICIENT_STOCK:Fresh Local Kale:1:1 Bunch');
    final container = await pumpCheckout(tester, cart, orders);
    expect(container.read(cartNotifierProvider), {'p_kale': 3});
    final getCartBefore = cart.getCartCalls;
    final summaryBefore = cart.summaryCalls;

    // Server-side the cart was adjusted (e.g. stock reduced) while the user was on checkout.
    cart.server['p_kale'] = 1;
    await placeOrder(tester);

    expect(find.text('Some items in your cart are no longer available in the requested quantity.'), findsOneWidget);
    expect(cart.getCartCalls, greaterThan(getCartBefore));
    expect(cart.summaryCalls, greaterThan(summaryBefore));
    expect(container.read(cartNotifierProvider), {'p_kale': 1});
    expect(cart.writes, 0, reason: 'reconciliation must not push the stale local cart back to the server');
    expect(find.byType(CheckoutScreen), findsOneWidget);
  });

  testWidgets('a rejected order whose server cart is now empty returns to the cart screen', (tester) async {
    final cart = _ServerCart({'p_kale': 2});
    final orders = _OrderRepo(cart, failureCode: 'INSUFFICIENT_STOCK');
    final container = await pumpCheckout(tester, cart, orders);

    cart.server.clear();
    await placeOrder(tester);
    await tester.pumpAndSettle();

    expect(container.read(cartNotifierProvider), isEmpty);
    expect(find.text('CART SCREEN'), findsOneWidget);
  });

  testWidgets('a successful order clears the local cart without writing it back to the server', (tester) async {
    final cart = _ServerCart({'p_kale': 2});
    final orders = _OrderRepo(cart);
    final container = await pumpCheckout(tester, cart, orders);

    await placeOrder(tester);

    expect(find.text('ORDER SUCCESS'), findsOneWidget);
    expect(container.read(cartNotifierProvider), isEmpty);
    expect(cart.server, isEmpty);
    expect(cart.writes, 0);
  });

  group('D-012 product quantity rules at checkout', () {
    const configuredKale = ProductModel(
      id: 'p_kale',
      categoryId: 'c',
      name: 'Fresh Local Kale',
      price: 60.0,
      unit: 'KG',
      stockQuantity: 15.0,
      minQuantity: 1,
      maxQuantity: 5,
      quantityStep: 0.5,
    );

    testWidgets('a quantity outside the product rule blocks ordering with a clear message', (tester) async {
      final cart = _ServerCart({'p_kale': 0.75});
      final orders = _OrderRepo(cart);
      await pumpCheckout(tester, cart, orders, products: const [configuredKale]);

      expect(find.text('Some item quantities are outside the allowed limits. Please update your cart.'), findsOneWidget);
      await placeOrder(tester);
      expect(orders.lastItems, isNull, reason: 'createOrder must not be called');
    });

    testWidgets('a valid decimal quantity is sent unchanged in the order payload', (tester) async {
      final cart = _ServerCart({'p_kale': 1.5});
      final orders = _OrderRepo(cart);
      await pumpCheckout(tester, cart, orders, products: const [configuredKale]);

      await placeOrder(tester);
      expect(orders.lastItems, [
        {'productId': 'p_kale', 'quantity': 1.5},
      ]);
      expect(find.text('ORDER SUCCESS'), findsOneWidget);
    });

    testWidgets('"+" steps by the product step and stops at the configured maximum', (tester) async {
      final cart = _ServerCart({'p_kale': 4.5});
      final orders = _OrderRepo(cart);
      final container = await pumpCheckout(tester, cart, orders, products: const [configuredKale]);

      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pumpAndSettle();
      expect(container.read(cartNotifierProvider)['p_kale'], 5);

      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pumpAndSettle();
      expect(container.read(cartNotifierProvider)['p_kale'], 5);
      expect(cart.server['p_kale'], 5);
    });
  });
}
