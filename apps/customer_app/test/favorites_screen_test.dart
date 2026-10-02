import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:customer_app/features/home/data/models/banner_model.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/data/repositories/home_repository.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:customer_app/shared/widgets/app_bottom_nav_bar.dart';
import 'package:customer_app/shared/widgets/app_product_card.dart';
import 'package:customer_app/shared/widgets/checkout_bar.dart';
import 'package:customer_app/shared/widgets/product_quantity_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const sampleProducts = [
  ProductModel(
    id: 'p_avocado',
    categoryId: 'cat_fruits',
    categoryName: 'Fruits',
    name: 'Organic Hass Avocado',
    description: 'Creamy Hass avocados',
    price: 200.0,
    mrp: 240.0,
    unit: 'Pack of 2',
    stockQuantity: 15.0,
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_kale',
    categoryId: 'cat_greens',
    categoryName: 'Organic Greens',
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
    id: 'p_berries',
    categoryId: 'cat_fruits',
    categoryName: 'Berries',
    name: 'Fresh Blueberries',
    description: 'Sweet fresh blueberries',
    price: 350.0,
    mrp: 400.0,
    unit: '1 Box',
    stockQuantity: 0.0, // Out of stock
    isAvailable: true,
    isActive: true,
  ),
];

class _MockFavoritesHomeRepository implements HomeRepository {
  final List<ProductModel> products;
  _MockFavoritesHomeRepository({this.products = sampleProducts});

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

Widget _createFavoritesTestWidget({
  Set<String>? initialFavorites,
  Map<String, int>? initialCart,
  ThemeMode themeMode = ThemeMode.light,
  LocalStorageService? localStorage,
  List<ProductModel>? products,
  GoRouter? customRouter,
}) {
  final container = ProviderContainer(
    overrides: [
      if (localStorage != null)
        localStorageProvider.overrideWithValue(localStorage),
      homeRepositoryProvider.overrideWithValue(
        _MockFavoritesHomeRepository(products: products ?? sampleProducts),
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
          distanceKm: 0.93,
        ),
      ),
    ],
  );

  if (initialFavorites != null) {
    container.read(favoritesNotifierProvider.notifier).setFavorites(initialFavorites);
  }

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
      home: const FavoritesScreen(),
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

  group('Screen 14 — Favourites & Screen 15 — Empty Favourites Tests', () {
    test('1. Favourites route constant is registered correctly', () {
      expect(RouteNames.favorites, equals('/favorites'));
    });

    testWidgets('2. Screen 15 renders Empty Favourites state when no products are favorited', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createFavoritesTestWidget(
        localStorage: localStorage,
        initialFavorites: {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Favourites'), findsWidgets);
      expect(find.text('No favourites yet'), findsOneWidget);
      expect(find.text('Save products you love and find them here for quick ordering.'), findsOneWidget);
      expect(find.text('Explore Products'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('3. Screen 14 renders Populated Favourites with items, header, and count', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createFavoritesTestWidget(
        localStorage: localStorage,
        initialFavorites: {'p_avocado', 'p_kale'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Favourites'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('Organic Hass Avocado'), findsOneWidget);
      expect(find.text('Fresh Local Kale'), findsOneWidget);
      expect(find.byType(AppProductCard), findsNWidgets(2));
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('4. Tapping heart icon unfavorites item and removes it in real time', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createFavoritesTestWidget(
        localStorage: localStorage,
        initialFavorites: {'p_avocado', 'p_kale'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('2 items'), findsOneWidget);

      // Find the favorite heart buttons on AppProductCard
      final favoriteIcons = find.byIcon(Icons.favorite_rounded);
      expect(favoriteIcons, findsWidgets);

      // Tap heart on the first product
      await tester.tap(favoriteIcons.first);
      await tester.pumpAndSettle();

      // Now only 1 item should remain
      expect(find.text('1 item'), findsOneWidget);
    });

    testWidgets('5. Removing final favourite product transitions automatically to Empty state', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createFavoritesTestWidget(
        localStorage: localStorage,
        initialFavorites: {'p_avocado'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 item'), findsOneWidget);

      // Tap heart to remove the single item
      final heartIcon = find.byIcon(Icons.favorite_rounded);
      await tester.tap(heartIcon.first);
      await tester.pumpAndSettle();

      // Screen 15 Empty state should be visible
      expect(find.text('No favourites yet'), findsOneWidget);
      expect(find.text('Explore Products'), findsOneWidget);
    });

    testWidgets('6. Start/Explore Products button navigates to Explore', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      bool navigatedToExplore = false;

      final router = GoRouter(
        initialLocation: '/favorites',
        routes: [
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) {
              navigatedToExplore = true;
              return const Scaffold(body: Text('Explore Screen Destination'));
            },
          ),
        ],
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createFavoritesTestWidget(
        localStorage: localStorage,
        initialFavorites: {},
        customRouter: router,
      ));
      await tester.pumpAndSettle();

      final exploreBtn = find.text('Explore Products');
      expect(exploreBtn, findsOneWidget);
      await tester.tap(exploreBtn);
      await tester.pumpAndSettle();

      expect(navigatedToExplore, isTrue);
    });

    testWidgets('7. In-stock product card opens Product Details', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      String? selectedProductId;

      final router = GoRouter(
        initialLocation: '/favorites',
        routes: [
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/product-details',
            builder: (context, state) {
              selectedProductId = state.uri.queryParameters['productId'];
              return Scaffold(body: Text('Details for $selectedProductId'));
            },
          ),
        ],
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createFavoritesTestWidget(
        localStorage: localStorage,
        initialFavorites: {'p_avocado'},
        customRouter: router,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Organic Hass Avocado'));
      await tester.pumpAndSettle();

      expect(selectedProductId, equals('p_avocado'));
    });

    testWidgets('8. Out-of-stock product is not visible in favorites and renders empty state', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      bool navigatedToDetails = false;

      final router = GoRouter(
        initialLocation: '/favorites',
        routes: [
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/product-details',
            builder: (context, state) {
              navigatedToDetails = true;
              return const Scaffold(body: Text('Details'));
            },
          ),
        ],
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createFavoritesTestWidget(
        localStorage: localStorage,
        initialFavorites: {'p_berries'}, // Out of stock
        customRouter: router,
      ));
      await tester.pumpAndSettle();

      // Out of stock product is omitted
      expect(find.text('Fresh Blueberries'), findsNothing);
      expect(find.text('No favourites yet'), findsOneWidget);
      expect(navigatedToDetails, isFalse);
    });

    testWidgets('9. Adding product to cart updates CheckoutBar reactively', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createFavoritesTestWidget(
        localStorage: localStorage,
        initialFavorites: {'p_avocado'},
        initialCart: {},
      ));
      await tester.pumpAndSettle();

      // Find the add to cart button inside AppProductCard
      final addBtn = find.byIcon(Icons.add_rounded);
      expect(addBtn, findsOneWidget);

      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // CheckoutBar should appear
      expect(find.byType(CheckoutBar), findsOneWidget);
      expect(find.byType(ProductQuantityControl), findsOneWidget);
    });

    testWidgets('10. Bottom navigation highlights Favorite tab (index 3)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createFavoritesTestWidget(
        localStorage: localStorage,
        initialFavorites: {'p_avocado'},
      ));
      await tester.pumpAndSettle();

      final navBarFinder = find.byType(AppBottomNavBar);
      expect(navBarFinder, findsOneWidget);
      final navBar = tester.widget<AppBottomNavBar>(navBarFinder);
      expect(navBar.selectedIndex, equals(3));
    });

    testWidgets('11. Dark theme renders correctly without crash', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createFavoritesTestWidget(
        localStorage: localStorage,
        initialFavorites: {'p_avocado'},
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Organic Hass Avocado'), findsOneWidget);
    });

    testWidgets('12. Responsive layout on small and large phones without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final testSizes = [
        const Size(320 * 3, 600 * 3), // Small 320dp width
        const Size(390 * 3, 844 * 3), // Standard 390dp
        const Size(430 * 3, 932 * 3), // Large iPhone Pro Max
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(_createFavoritesTestWidget(
          localStorage: localStorage,
          initialFavorites: {'p_avocado', 'p_kale'},
          initialCart: {'p_avocado': 1},
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AppProductCard), findsNWidgets(2));
      }
      tester.view.resetPhysicalSize();
    });
  });
}
