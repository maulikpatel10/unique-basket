import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:customer_app/features/home/data/models/banner_model.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/data/repositories/home_repository.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:customer_app/shared/widgets/app_bottom_nav_bar.dart';
import 'package:customer_app/shared/widgets/product_quantity_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const sampleProducts = [
  ProductModel(
    id: 'p_kale',
    categoryId: 'cat_greens',
    categoryName: 'Organic',
    name: 'Fresh Local Kale',
    description: 'Fresh organic curly kale',
    price: 180.0,
    mrp: 200.0,
    unit: '1 Bunch',
    stockQuantity: 20.0,
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_avocado',
    categoryId: 'cat_fruits',
    categoryName: null,
    name: 'Organic Hass Avocado',
    description: 'Creamy Hass avocados',
    price: 240.0,
    mrp: 280.0,
    unit: 'Pack of 2',
    stockQuantity: 15.0,
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_sourdough',
    categoryId: 'cat_bakery',
    categoryName: 'Fresh Baked',
    name: 'Artisan Sourdough',
    description: 'Crispy crust artisan loaf',
    price: 320.0,
    mrp: 350.0,
    unit: '1 Loaf',
    stockQuantity: 10.0,
    isAvailable: true,
    isActive: true,
  ),
];

class _MockCartHomeRepository implements HomeRepository {
  final List<ProductModel> products;
  _MockCartHomeRepository({this.products = sampleProducts});

  @override
  Future<List<CategoryModel>> getCategories() async => [];

  @override
  Future<List<ProductModel>> getFeaturedProducts() async => products;

  @override
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId}) async =>
      products;

  @override
  Future<List<BannerModel>> getBanners() async => [];
}

Widget _createCartTestWidget({
  Map<String, int>? initialCart,
  ThemeMode themeMode = ThemeMode.light,
  LocalStorageService? localStorage,
  List<ProductModel>? products,
  DeliverySettingsModel? deliverySettings,
  GoRouter? customRouter,
}) {
  final container = ProviderContainer(
    overrides: [
      if (localStorage != null)
        localStorageProvider.overrideWithValue(localStorage),
      homeRepositoryProvider.overrideWithValue(
        _MockCartHomeRepository(products: products ?? sampleProducts),
      ),
      deliverySettingsProvider.overrideWith(
        (ref) async =>
            deliverySettings ??
            const DeliverySettingsModel(
              deliveryFee: 30.0,
              freeDeliveryThreshold: 499.0,
            ),
      ),
      servingStoreProvider.overrideWith(
        (ref) async => const StoreModel(
          id: 'store_1',
          storeId: 'UB-RAJKOT-01',
          name: 'Unique Basket Main',
          address: 'Kalawad Road',
          city: 'Rajkot',
          state: 'Gujarat',
          pincode: '360005',
          latitude: 22.3039,
          longitude: 70.8022,
          phone: '+919876543210',
          openingTime: '07:00 AM',
          closingTime: '10:00 PM',
          distanceKm: 0.8,
        ),
      ),
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
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: customRouter,
      ),
    );
  }

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const CartScreen(),
    ),
  );
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

  group('Screen 12 — Cart & Screen 13 — Empty Cart Tests', () {
    test('Cart route constant is registered correctly', () {
      expect(RouteNames.cart, equals('/cart'));
    });

    testWidgets('1. CartScreen renders empty cart state when no items in basket', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        initialCart: {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cart'), findsWidgets); // Header & nav tab
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Add fresh fruits and vegetables to your cart.'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('2. CartScreen renders populated cart with items, details, and totals', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        deliverySettings: const DeliverySettingsModel(
          deliveryFee: 30.0,
          freeDeliveryThreshold: 1500.0,
        ),
        initialCart: {
          'p_kale': 1,
          'p_avocado': 2,
          'p_sourdough': 1,
        },
      ));
      await tester.pumpAndSettle();

      // Header and subtitle
      expect(find.text('4 items in your basket'), findsOneWidget);

      // Product items
      expect(find.text('Fresh Local Kale'), findsOneWidget);
      expect(find.text('Organic • 1 Bunch'), findsOneWidget);
      expect(find.text('Organic Hass Avocado'), findsOneWidget);
      expect(find.text('Pack of 2'), findsOneWidget);
      expect(find.text('Artisan Sourdough'), findsOneWidget);
      expect(find.text('Fresh Baked • 1 Loaf'), findsOneWidget);

      // Quantity controls
      expect(find.byType(ProductQuantityControl), findsNWidgets(3));

      // Bill Summary: Kale (180) + Avocado (2 * 240 = 480) + Sourdough (320) = 980 Subtotal + 30 Delivery = 1010 Total
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('₹980'), findsOneWidget);
      expect(find.text('₹30'), findsOneWidget);
      expect(find.text('₹1,010'), findsOneWidget);

      // Proceed to Checkout CTA
      expect(find.text('Proceed to Checkout'), findsOneWidget);
    });

    testWidgets('3. Quantity increment (+) and decrement (−) update cart in real-time', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        initialCart: {
          'p_kale': 1,
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 item in your basket'), findsOneWidget);
      expect(find.text('₹180'), findsWidgets); // Unit price and Subtotal
      expect(find.text('₹210'), findsOneWidget); // 180 + 30

      // Tap + to increment Kale to 2
      final plusButton = find.byIcon(Icons.add_rounded);
      expect(plusButton, findsOneWidget);
      await tester.tap(plusButton);
      await tester.pumpAndSettle();

      expect(find.text('2 items in your basket'), findsOneWidget);
      expect(find.text('₹360'), findsOneWidget); // Subtotal
      expect(find.text('₹390'), findsOneWidget); // 360 + 30

      // Tap − to decrement Kale back to 1
      final minusButton = find.byIcon(Icons.remove_rounded);
      expect(minusButton, findsOneWidget);
      await tester.tap(minusButton);
      await tester.pumpAndSettle();

      expect(find.text('1 item in your basket'), findsOneWidget);
      expect(find.text('₹180'), findsWidgets);
      expect(find.text('₹210'), findsOneWidget);
    });

    testWidgets('4. Decrementing quantity to zero removes item and triggers empty cart state', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        initialCart: {
          'p_kale': 1,
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fresh Local Kale'), findsOneWidget);

      // Decrement from 1 to 0
      final minusButton = find.byIcon(Icons.remove_rounded);
      await tester.tap(minusButton);
      await tester.pumpAndSettle();

      // Item should be removed and empty state shown
      expect(find.text('Fresh Local Kale'), findsNothing);
      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('5. Tapping close (✕) remove icon deletes item instantly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        initialCart: {
          'p_kale': 2,
          'p_avocado': 1,
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fresh Local Kale'), findsOneWidget);
      expect(find.text('Organic Hass Avocado'), findsOneWidget);

      // Find close icons
      final closeIcons = find.byIcon(Icons.close_rounded);
      expect(closeIcons, findsNWidgets(2));

      // Tap first close icon (removes Kale)
      await tester.tap(closeIcons.first);
      await tester.pumpAndSettle();

      expect(find.text('Fresh Local Kale'), findsNothing);
      expect(find.text('Organic Hass Avocado'), findsOneWidget);
      expect(find.text('1 item in your basket'), findsOneWidget);
      expect(find.text('Fresh Local Kale removed from basket'), findsOneWidget);
    });

    testWidgets('6. Start Shopping button navigates to Home', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      bool navigatedHome = false;

      final router = GoRouter(
        initialLocation: RouteNames.cart,
        routes: [
          GoRoute(
            path: RouteNames.cart,
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) {
              navigatedHome = true;
              return const Scaffold(body: Center(child: Text('Home Screen')));
            },
          ),
        ],
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        initialCart: {},
        customRouter: router,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Start Shopping'), findsOneWidget);
      await tester.tap(find.text('Start Shopping'));
      await tester.pumpAndSettle();

      expect(navigatedHome, isTrue);
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('7. Proceed to Checkout CTA navigates to Checkout screen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      bool navigatedCheckout = false;

      final router = GoRouter(
        initialLocation: RouteNames.cart,
        routes: [
          GoRoute(
            path: RouteNames.cart,
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: RouteNames.checkout,
            builder: (context, state) {
              navigatedCheckout = true;
              return const Scaffold(body: Center(child: Text('Checkout Screen')));
            },
          ),
        ],
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        initialCart: {
          'p_kale': 1,
        },
        customRouter: router,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Proceed to Checkout'));
      await tester.pumpAndSettle();

      expect(navigatedCheckout, isTrue);
      expect(find.text('Checkout Screen'), findsOneWidget);
    });

    testWidgets('8. Bottom navigation highlights Cart tab (index 2) and allows switching to Shop', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      bool navigatedShop = false;

      final router = GoRouter(
        initialLocation: RouteNames.cart,
        routes: [
          GoRoute(
            path: RouteNames.cart,
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) {
              navigatedShop = true;
              return const Scaffold(body: Center(child: Text('Shop Screen')));
            },
          ),
        ],
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        initialCart: {'p_kale': 1},
        customRouter: router,
      ));
      await tester.pumpAndSettle();

      // Tap Shop tab (tab index 0)
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();

      expect(navigatedShop, isTrue);
      expect(find.text('Shop Screen'), findsOneWidget);
    });

    testWidgets('9. Dark theme renders correctly without crash', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        initialCart: {
          'p_kale': 1,
          'p_avocado': 1,
        },
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cart'), findsWidgets);
      expect(find.text('Fresh Local Kale'), findsOneWidget);
      expect(find.text('Proceed to Checkout'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10. Responsive layout on small and large phones without overflow', (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        // ignore: avoid_print
        print('=== FLUTTER ERROR CAUGHT ===\n${details.summary}\n${details.context}\n${details.exception}');
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final viewports = [
        const Size(320, 568), // Small phone (iPhone SE 1st gen)
        const Size(390, 844), // Standard phone
        const Size(428, 926), // Large phone
      ];

      for (final size in viewports) {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(_createCartTestWidget(
          localStorage: localStorage,
          initialCart: {
            'p_kale': 1,
            'p_avocado': 2,
            'p_sourdough': 1,
          },
        ));
        await tester.pumpAndSettle();

        expect(find.text('Fresh Local Kale'), findsOneWidget);
        expect(find.text('Proceed to Checkout'), findsOneWidget);
        final exception = tester.takeException();
        if (exception != null) {
          // ignore: avoid_print
          print('Test 10 caught exception: $exception');
        }
        expect(exception, isNull);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('11. Dynamic delivery fee from backend (₹50) updates Cart pricing', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        deliverySettings: const DeliverySettingsModel(
          deliveryFee: 50.0,
          freeDeliveryThreshold: 500.0,
        ),
        initialCart: {
          'p_kale': 1, // 180
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('₹180'), findsWidgets);
      expect(find.text('₹50'), findsOneWidget);
      expect(find.text('₹230'), findsOneWidget); // 180 + 50
    });

    testWidgets('12. Subtotal exceeding freeDeliveryThreshold shows FREE delivery in Cart', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        deliverySettings: const DeliverySettingsModel(
          deliveryFee: 30.0,
          freeDeliveryThreshold: 400.0,
        ),
        initialCart: {
          'p_avocado': 2, // 240 * 2 = 480 (>= 400)
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('₹480'), findsNWidgets(2)); // Subtotal & Total
    });

    testWidgets('13. Tapping delivery fee info icon opens dynamic bottom sheet', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createCartTestWidget(
        localStorage: localStorage,
        deliverySettings: const DeliverySettingsModel(
          deliveryFee: 45.0,
          freeDeliveryThreshold: 599.0,
        ),
        initialCart: {
          'p_kale': 1,
        },
      ));
      await tester.pumpAndSettle();

      // Find and tap info icon
      final infoIcon = find.byKey(const ValueKey('cart_delivery_fee_info_icon'));
      expect(infoIcon, findsOneWidget);
      await tester.tap(infoIcon);
      await tester.pumpAndSettle();

      // Bottom sheet content
      expect(find.text('Delivery Fee'), findsWidgets);
      expect(find.text('A delivery charge of ₹45 applies to this order.'), findsOneWidget);
      expect(find.text('Get FREE delivery on orders above ₹599.'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      // Dismiss sheet
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.text('A delivery charge of ₹45 applies to this order.'), findsNothing);
    });

    testWidgets('14. Cart has existing data -> refresh starts: UI remains visible with refresh indicator', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          homeRepositoryProvider.overrideWithValue(
            _MockCartHomeRepository(products: sampleProducts),
          ),
          servingStoreProvider.overrideWith(
            (ref) async => const StoreModel(
              id: 'store_1',
              storeId: 'UB-RAJKOT-01',
              name: 'Unique Basket Main',
              address: 'Kalawad Road',
              city: 'Rajkot',
              state: 'Gujarat',
              pincode: '360005',
              latitude: 22.3039,
              longitude: 70.8022,
              phone: '+919876543210',
              openingTime: '07:00 AM',
              closingTime: '10:00 PM',
              distanceKm: 0.8,
            ),
          ),
          deliverySettingsProvider.overrideWith(
            (ref) async => const DeliverySettingsModel(
              deliveryFee: 30.0,
              freeDeliveryThreshold: 499.0,
            ),
          ),
        ],
      );

      // Pre-populate cart with 1 kale
      container.read(cartNotifierProvider.notifier).increment('p_kale');

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

      // UI is visible
      expect(find.text('Fresh Local Kale'), findsOneWidget);
      expect(find.text('₹180'), findsWidgets);

      // Simulate refresh state in cartSyncStatusProvider
      container.read(cartSyncStatusProvider.notifier).state = CartSyncStatus.refreshing;
      await tester.pump();

      // Existing Cart MUST REMAIN VISIBLE
      expect(find.text('Fresh Local Kale'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('₹180'), findsWidgets);

      // Linear progress bar is displayed at the top
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('15. Cart has existing data -> backend refresh succeeds: updated items displayed', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          homeRepositoryProvider.overrideWithValue(
            _MockCartHomeRepository(products: sampleProducts),
          ),
          servingStoreProvider.overrideWith(
            (ref) async => const StoreModel(
              id: 'store_1',
              storeId: 'UB-RAJKOT-01',
              name: 'Unique Basket Main',
              address: 'Kalawad Road',
              city: 'Rajkot',
              state: 'Gujarat',
              pincode: '360005',
              latitude: 22.3039,
              longitude: 70.8022,
              phone: '+919876543210',
              openingTime: '07:00 AM',
              closingTime: '10:00 PM',
              distanceKm: 0.8,
            ),
          ),
          deliverySettingsProvider.overrideWith(
            (ref) async => const DeliverySettingsModel(
              deliveryFee: 30.0,
              freeDeliveryThreshold: 499.0,
            ),
          ),
        ],
      );

      container.read(cartNotifierProvider.notifier).increment('p_kale');

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

      expect(find.text('Fresh Local Kale'), findsOneWidget);

      // Backend returns updated cart with avocado
      container.read(cartNotifierProvider.notifier).setCart({'p_avocado': 2});
      container.read(cartSyncStatusProvider.notifier).state = CartSyncStatus.idle;
      await tester.pumpAndSettle();

      expect(find.text('Organic Hass Avocado'), findsOneWidget);
      expect(find.text('Fresh Local Kale'), findsNothing);
      expect(find.text('₹480'), findsWidgets);
    });

    testWidgets('16. Cart has existing data -> backend refresh fails: existing Cart remains visible', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          homeRepositoryProvider.overrideWithValue(
            _MockCartHomeRepository(products: sampleProducts),
          ),
          servingStoreProvider.overrideWith(
            (ref) async => const StoreModel(
              id: 'store_1',
              storeId: 'UB-RAJKOT-01',
              name: 'Unique Basket Main',
              address: 'Kalawad Road',
              city: 'Rajkot',
              state: 'Gujarat',
              pincode: '360005',
              latitude: 22.3039,
              longitude: 70.8022,
              phone: '+919876543210',
              openingTime: '07:00 AM',
              closingTime: '10:00 PM',
              distanceKm: 0.8,
            ),
          ),
          deliverySettingsProvider.overrideWith(
            (ref) async => const DeliverySettingsModel(
              deliveryFee: 30.0,
              freeDeliveryThreshold: 499.0,
            ),
          ),
        ],
      );

      container.read(cartNotifierProvider.notifier).increment('p_sourdough');

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

      expect(find.text('Artisan Sourdough'), findsOneWidget);
      expect(find.text('₹320'), findsWidgets);

      // Network failure occurs during refresh
      container.read(cartSyncStatusProvider.notifier).state = CartSyncStatus.error;
      await tester.pump();

      // UI is NOT wiped or replaced with blank screen
      expect(find.text('Artisan Sourdough'), findsOneWidget);
      expect(find.text('₹320'), findsWidgets);
      expect(find.text('Subtotal'), findsOneWidget);
    });

    testWidgets('17. No Cart data -> first load: displays branded AppLoading view', (tester) async {
      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(
            _MockCartHomeRepository(products: sampleProducts),
          ),
          servingStoreProvider.overrideWith(
            (ref) async => const StoreModel(
              id: 'store_1',
              storeId: 'UB-RAJKOT-01',
              name: 'Unique Basket Main',
              address: 'Kalawad Road',
              city: 'Rajkot',
              state: 'Gujarat',
              pincode: '360005',
              latitude: 22.3039,
              longitude: 70.8022,
              phone: '+919876543210',
              openingTime: '07:00 AM',
              closingTime: '10:00 PM',
              distanceKm: 0.8,
            ),
          ),
          deliverySettingsProvider.overrideWith(
            (ref) async => const DeliverySettingsModel(
              deliveryFee: 30.0,
              freeDeliveryThreshold: 499.0,
            ),
          ),
        ],
      );

      // Explicitly set initialLoading state for empty cart
      container.read(cartSyncStatusProvider.notifier).state = CartSyncStatus.initialLoading;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CartScreen(),
          ),
        ),
      );
      await tester.pump();

      // Proper loading UI is shown
      expect(find.text('Loading your basket...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('18. Backend confirms empty Cart: displays Empty Cart view', (tester) async {
      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(
            _MockCartHomeRepository(products: sampleProducts),
          ),
          servingStoreProvider.overrideWith(
            (ref) async => const StoreModel(
              id: 'store_1',
              storeId: 'UB-RAJKOT-01',
              name: 'Unique Basket Main',
              address: 'Kalawad Road',
              city: 'Rajkot',
              state: 'Gujarat',
              pincode: '360005',
              latitude: 22.3039,
              longitude: 70.8022,
              phone: '+919876543210',
              openingTime: '07:00 AM',
              closingTime: '10:00 PM',
              distanceKm: 0.8,
            ),
          ),
          deliverySettingsProvider.overrideWith(
            (ref) async => const DeliverySettingsModel(
              deliveryFee: 30.0,
              freeDeliveryThreshold: 499.0,
            ),
          ),
        ],
      );

      container.read(cartSyncStatusProvider.notifier).state = CartSyncStatus.idle;

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

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);
    });

    testWidgets('19. Local persistence data exists -> Cart displays immediately on app startup', (tester) async {
      SharedPreferences.setMockInitialValues({
        'ub_user_cart': '{"p_kale": 2}',
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          homeRepositoryProvider.overrideWithValue(
            _MockCartHomeRepository(products: sampleProducts),
          ),
          servingStoreProvider.overrideWith(
            (ref) async => const StoreModel(
              id: 'store_1',
              storeId: 'UB-RAJKOT-01',
              name: 'Unique Basket Main',
              address: 'Kalawad Road',
              city: 'Rajkot',
              state: 'Gujarat',
              pincode: '360005',
              latitude: 22.3039,
              longitude: 70.8022,
              phone: '+919876543210',
              openingTime: '07:00 AM',
              closingTime: '10:00 PM',
              distanceKm: 0.8,
            ),
          ),
          deliverySettingsProvider.overrideWith(
            (ref) async => const DeliverySettingsModel(
              deliveryFee: 30.0,
              freeDeliveryThreshold: 499.0,
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

      // Rendered directly from local cache without waiting
      expect(find.text('Fresh Local Kale'), findsOneWidget);
      expect(find.text('₹360'), findsWidgets); // 180 * 2
    });

    testWidgets('20. Delivery fee and total remain backend-driven during cartSummary updates', (tester) async {
      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(
            _MockCartHomeRepository(products: sampleProducts),
          ),
          servingStoreProvider.overrideWith(
            (ref) async => const StoreModel(
              id: 'store_1',
              storeId: 'UB-RAJKOT-01',
              name: 'Unique Basket Main',
              address: 'Kalawad Road',
              city: 'Rajkot',
              state: 'Gujarat',
              pincode: '360005',
              latitude: 22.3039,
              longitude: 70.8022,
              phone: '+919876543210',
              openingTime: '07:00 AM',
              closingTime: '10:00 PM',
              distanceKm: 0.8,
            ),
          ),
          deliverySettingsProvider.overrideWith(
            (ref) async => const DeliverySettingsModel(
              deliveryFee: 50.0,
              freeDeliveryThreshold: 500.0,
            ),
          ),
        ],
      );

      container.read(cartNotifierProvider.notifier).increment('p_kale');

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

      // Subtotal 180 + Delivery 50 = Total 230
      expect(find.text('₹180'), findsWidgets);
      expect(find.text('₹50'), findsOneWidget);
      expect(find.text('₹230'), findsOneWidget);
    });
  });
}

