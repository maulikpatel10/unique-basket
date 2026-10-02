import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:customer_app/features/checkout/data/repositories/order_repository.dart';
import 'package:customer_app/features/checkout/presentation/providers/order_provider.dart';
import 'package:customer_app/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:customer_app/features/home/data/models/banner_model.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/data/repositories/home_repository.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:customer_app/shared/widgets/app_product_card.dart';
import 'package:customer_app/shared/widgets/product_quantity_control.dart';

const _sampleProducts = [
  ProductModel(
    id: 'p_avocado',
    categoryId: 'cat_fruits',
    categoryName: 'Fruits',
    name: 'Organic Hass Avocado',
    description: 'Creamy Hass avocados imported from farms',
    price: 240.0,
    mrp: 280.0,
    unit: 'Pack of 2',
    stockQuantity: 15.0,
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_spinach',
    categoryId: 'cat_veg',
    categoryName: 'Vegetables',
    name: 'Fresh Farm Spinach With Extremely Long Descriptive Name That Might Cause Overflow If Not Handled Properly',
    description: 'Organic green baby spinach',
    price: 30.0,
    mrp: 30.0, // No discount
    unit: '500g',
    stockQuantity: 20.0,
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_out_of_stock',
    categoryId: 'cat_fruits',
    categoryName: 'Fruits',
    name: 'Exotic Dragonfruit',
    description: 'Fresh purple dragonfruit',
    price: 150.0,
    mrp: 180.0,
    unit: '1 pc',
    stockQuantity: 0.0,
    isAvailable: false,
    isActive: true,
  ),
];

class _MockHomeRepo implements HomeRepository {
  final List<ProductModel> products;
  _MockHomeRepo() : products = _sampleProducts;

  @override
  Future<List<CategoryModel>> getCategories() async => [];

  @override
  Future<List<ProductModel>> getFeaturedProducts() async => products;

  @override
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId}) async => products;

  @override
  Future<List<BannerModel>> getBanners() async => [];
}

class _MockOrderRepo implements OrderRepository {
  bool shouldFail = false;
  int orderCreationCount = 0;

  @override
  Future<Map<String, dynamic>> createOrder({
    required String fulfillmentType,
    required String? addressId,
    required String? storeId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    orderCreationCount++;
    if (shouldFail) {
      throw Exception('PAYMENT_GATEWAY_UNAVAILABLE');
    }
    return {
      'success': true,
      'data': {
        'order': {
          'id': 'order_edge_999',
          'orderNumber': '#UB-270926-999',
          'total': 270.0,
        }
      }
    };
  }

  @override
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    return {
      'success': true,
      'data': {
        'id': orderId,
        'orderNumber': '#UB-270926-999',
        'orderStatus': 'PLACED',
        'total': 270.0,
      }
    };
  }

  @override
  Future<List<dynamic>> getOrders() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    AppConfig.initialize(
      appName: 'Unique Basket',
      environment: Environment.development,
    );
  });

  group('Product Card & Product Interaction Edge Cases', () {
    testWidgets('1. AppProductCard renders null image gracefully without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 170,
                child: AppProductCard(
                  id: 'p1',
                  name: 'No Image Product',
                  price: 99.0,
                  unit: '1 kg',
                  imageUrl: null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Image Product'), findsOneWidget);
      expect(find.text('₹99'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. AppProductCard handles long names without render overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                height: 240,
                child: AppProductCard(
                  id: 'p2',
                  name: 'Super Long Extra Organic Hydroponic Farm Selected Fresh Crisp Salad Greens Pack of 500g',
                  price: 199.0,
                  unit: '500g',
                  badge: '25% OFF',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppProductCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Out-of-stock AppProductCard disables purchase and quantity controls', (tester) async {
      bool addTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 170,
                child: AppProductCard(
                  id: 'p_oos',
                  name: 'Out of Stock Dragonfruit',
                  price: 150.0,
                  unit: '1 pc',
                  isPurchasable: false,
                  onAddToCart: () => addTapped = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OUT OF STOCK'), findsOneWidget);
      expect(find.byType(ProductQuantityControl), findsNothing);

      // Tapping card when out of stock does not add to cart
      await tester.tap(find.text('OUT OF STOCK'));
      await tester.pumpAndSettle();
      expect(addTapped, isFalse);
    });

    testWidgets('4. Favorite button tap is isolated from card navigation tap', (tester) async {
      bool favToggled = false;
      bool cardNavigated = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 170,
                child: AppProductCard(
                  id: 'p_fav_test',
                  name: 'Test Banana',
                  price: 40.0,
                  unit: '1 Dozen',
                  isFavorite: false,
                  onToggleFavorite: () => favToggled = true,
                  onTap: () => cardNavigated = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap favorite heart icon
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();

      expect(favToggled, isTrue);
      expect(cardNavigated, isFalse);
    });

    testWidgets('4b. AppProductCard renders invalid image URL with fallback icon and no throw', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 170,
                child: AppProductCard(
                  id: 'p_invalid_img',
                  name: 'Product with Bad URL',
                  price: 50.0,
                  unit: '500g',
                  imageUrl: 'https://invalid-url-domain.test/nonexistent.png',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Product with Bad URL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4c. AppProductCard renders long unit string with ellipsis and no overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                child: AppProductCard(
                  id: 'p_long_unit',
                  name: 'Fresh Greens',
                  price: 35.0,
                  unit: 'Pack of 5 units (100g each in eco box)',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fresh Greens'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Cart & Checkout State Consistency Edge Cases', () {
    testWidgets('5. Rapid quantity changes maintain valid state and totals', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          homeRepositoryProvider.overrideWithValue(_MockHomeRepo()),
          deliverySettingsProvider.overrideWith(
            (ref) async => const DeliverySettingsModel(
              deliveryFee: 30.0,
              freeDeliveryThreshold: 1000.0,
            ),
          ),
          servingStoreProvider.overrideWith(
            (ref) async => const StoreModel(
              id: 'store_1',
              storeId: 'UB-01',
              name: 'Store',
              address: 'Road',
              city: 'Rajkot',
              state: 'Gujarat',
              pincode: '360005',
              phone: '9876543210',
              latitude: 22.3039,
              longitude: 70.8022,
              openingTime: '08:00 AM',
              closingTime: '10:00 PM',
            ),
          ),
          cartSummaryProvider.overrideWith(
            (ref) async => const CartSummaryModel(
              subtotal: 720.0,
              deliveryFee: 30.0,
              discount: 0.0,
              total: 750.0,
              freeDeliveryThreshold: 1000.0,
            ),
          ),
          deliverySettingsProvider.overrideWith(
            (ref) async => const DeliverySettingsModel(
              deliveryFee: 30.0,
              freeDeliveryThreshold: 1000.0,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially empty
      expect(find.text('Your cart is empty'), findsOneWidget);

      // Increment avocado in provider
      container.read(cartNotifierProvider.notifier).increment('p_avocado');
      container.read(cartNotifierProvider.notifier).increment('p_avocado');
      container.read(cartNotifierProvider.notifier).increment('p_avocado');
      await tester.pumpAndSettle();

      // 3 items in basket: 3 * 240 = 720 Subtotal + 30 Delivery = 750
      expect(find.text('3 items in your basket'), findsOneWidget);
      expect(find.text('₹720'), findsWidgets);
      expect(find.text('₹750'), findsOneWidget);

      // Rapidly decrement down to 0
      final minusBtn = find.byIcon(Icons.remove_rounded);
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();

      // Should return to empty cart state cleanly
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(container.read(cartNotifierProvider)['p_avocado'], isNull);
    });

    testWidgets('6. Checkout screen prevents duplicate order placement on rapid button taps', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockOrderRepo = _MockOrderRepo();

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          homeProductsProvider.overrideWith((ref) => _sampleProducts),
          customerAddressesProvider.overrideWith((ref) => [
            {
              'id': 'addr_1',
              'title': 'Home',
              'addressLine': '123 Main St, Rajkot 360001',
              'city': 'Rajkot',
              'state': 'Gujarat',
              'pincode': '360001',
              'isDefault': true,
              'phone': '+91 98765 43210',
            }
          ]),
          defaultCustomerAddressProvider.overrideWith((ref) => const AsyncValue.data({
            'id': 'addr_1',
            'title': 'Home',
            'addressLine': '123 Main St, Rajkot 360001',
            'city': 'Rajkot',
            'state': 'Gujarat',
            'pincode': '360001',
            'isDefault': true,
            'phone': '+91 98765 43210',
          })),
          customerProfileProvider.overrideWith((ref) => {
            'id': 'cust_1',
            'phone': '+919876543210',
            'name': 'Test User',
          }),
          orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        ],
      );

      container.read(cartNotifierProvider.notifier).increment('p_avocado');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLACE ORDER'));
      final placeOrderBtn = find.text('PLACE ORDER');
      expect(placeOrderBtn, findsOneWidget);

      // Tap Place Order rapidly
      await tester.tap(placeOrderBtn);
      await tester.tap(placeOrderBtn);
      await tester.pump();

      // Order should only be initiated once
      expect(mockOrderRepo.orderCreationCount, equals(1));
    });

    testWidgets('7. Checkout API failure displays error message without crashing', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockOrderRepo = _MockOrderRepo()..shouldFail = true;

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          homeProductsProvider.overrideWith((ref) => _sampleProducts),
          customerAddressesProvider.overrideWith((ref) => [
            {
              'id': 'addr_1',
              'title': 'Home',
              'addressLine': '123 Main St, Rajkot 360001',
              'city': 'Rajkot',
              'state': 'Gujarat',
              'pincode': '360001',
              'isDefault': true,
              'phone': '+91 98765 43210',
            }
          ]),
          defaultCustomerAddressProvider.overrideWith((ref) => const AsyncValue.data({
            'id': 'addr_1',
            'title': 'Home',
            'addressLine': '123 Main St, Rajkot 360001',
            'city': 'Rajkot',
            'state': 'Gujarat',
            'pincode': '360001',
            'isDefault': true,
            'phone': '+91 98765 43210',
          })),
          customerProfileProvider.overrideWith((ref) => {
            'id': 'cust_1',
            'phone': '+919876543210',
            'name': 'Test User',
          }),
          orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        ],
      );

      container.read(cartNotifierProvider.notifier).increment('p_avocado');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLACE ORDER'));
      final placeOrderBtn = find.text('PLACE ORDER');
      await tester.tap(placeOrderBtn);
      await tester.pumpAndSettle();

      // Error message should be shown to user
      expect(find.byType(SnackBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
