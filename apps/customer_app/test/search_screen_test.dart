import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/utils/currency_formatter.dart';
import 'package:customer_app/features/home/data/models/banner_model.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/data/repositories/home_repository.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/search/presentation/screens/search_screen.dart';
import 'package:customer_app/features/search/presentation/widgets/search_no_results_card.dart';
import 'package:customer_app/features/search/presentation/widgets/search_query_suggestion_item.dart';
import 'package:customer_app/features/search/presentation/widgets/search_suggestion_row.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:customer_app/shared/widgets/app_bottom_nav_bar.dart';
import 'package:customer_app/shared/widgets/app_product_card.dart';
import 'package:customer_app/shared/widgets/app_search_bar.dart';
import 'package:customer_app/shared/widgets/checkout_bar.dart';

const sampleCategories = [
  CategoryModel(
    id: 'cat_fruits',
    name: 'Fresh Fruits',
    imageUrl: 'https://example.com/fruits.png',
    isActive: true,
  ),
  CategoryModel(
    id: 'cat_veggies',
    name: 'Fresh Vegetables',
    imageUrl: 'https://example.com/veggies.png',
    isActive: true,
  ),
];

const sampleProducts = [
  ProductModel(
    id: 'p_apple_gala',
    categoryId: 'cat_fruits',
    categoryName: 'Fresh Fruits',
    name: 'Apple — Fresh Royal Gala',
    description: 'Crisp and sweet fresh Gala apples',
    price: 140.0,
    mrp: 180.0,
    unit: '1 kg',
    stockQuantity: 15.0,
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_apple_kashmir',
    categoryId: 'cat_fruits',
    categoryName: 'Fresh Fruits',
    name: 'Apple — Kashmir Premium',
    description: 'Direct from Kashmir valleys',
    price: 220.0,
    mrp: 250.0,
    unit: '4 pcs',
    badge: 'Bestseller',
    stockQuantity: 10.0,
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_apple_granny',
    categoryId: 'cat_fruits',
    categoryName: 'Fresh Fruits',
    name: 'Green Apple — Granny Smith',
    description: 'Tangy and crisp sour green apples',
    price: 190.0,
    mrp: 210.0,
    unit: '500g',
    stockQuantity: 8.0,
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_out_of_stock_apple',
    categoryId: 'cat_fruits',
    categoryName: 'Fresh Fruits',
    name: 'Organic Honeycrisp Apple',
    description: 'Rare organic honeycrisp apples',
    price: 299.0,
    mrp: 350.0,
    unit: '500g',
    stockQuantity: 0.0, // Out of stock
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_banana',
    categoryId: 'cat_fruits',
    categoryName: 'Fresh Fruits',
    name: 'Fresh Robusta Bananas',
    description: 'Sweet golden bananas',
    price: 50.0,
    mrp: 60.0,
    unit: '1 Dozen',
    stockQuantity: 20.0,
    isAvailable: true,
    isActive: true,
  ),
];

class _MockSearchHomeRepository implements HomeRepository {
  final List<ProductModel> products;
  final List<CategoryModel> categories;

  _MockSearchHomeRepository({
    this.products = sampleProducts,
    this.categories = sampleCategories,
  });

  @override
  Future<List<CategoryModel>> getCategories() async => categories;

  @override
  Future<List<ProductModel>> getFeaturedProducts() async => products;

  @override
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId}) async {
    if (categoryId != null && categoryId.isNotEmpty) {
      return products.where((p) => p.categoryId == categoryId).toList();
    }
    return products;
  }

  @override
  Future<List<BannerModel>> getBanners() async => [];
}

Widget _createSearchTestWidget({
  String? initialQuery,
  Map<String, int>? initialCart,
  Set<String>? initialFavorites,
  ThemeMode themeMode = ThemeMode.light,
  LocalStorageService? localStorage,
  List<ProductModel>? products,
  List<CategoryModel>? categories,
  GoRouter? customRouter,
}) {
  final container = ProviderContainer(
    overrides: [
      if (localStorage != null)
        localStorageProvider.overrideWithValue(localStorage),
      homeRepositoryProvider.overrideWithValue(
        _MockSearchHomeRepository(
          products: products ?? sampleProducts,
          categories: categories ?? sampleCategories,
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
          distanceKm: 0.93,
        ),
      ),
    ],
  );

  if (initialFavorites != null) {
    for (final id in initialFavorites) {
      container.read(favoritesNotifierProvider.notifier).toggleFavorite(id);
    }
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
      home: SearchScreen(initialQuery: initialQuery),
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

  group('Screen 17–19 — Search Feature Comprehensive Tests', () {
    test('1. Search route constant is registered correctly', () {
      expect(RouteNames.search, equals('/search'));
    });

    testWidgets('2. Search screen renders with AppSearchBar, AppBottomNavBar, and popular searches',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.byType(AppSearchBar), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.text('RECENT SEARCHES'), findsOneWidget);
      expect(find.text('POPULAR SEARCHES'), findsOneWidget);
      expect(find.text('Fresh Apples'), findsWidgets);
    });

    testWidgets('3. Typing in search bar triggers live product suggestions matching query (Screen 17)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      expect(searchInput, findsOneWidget);

      await tester.enterText(searchInput, 'apple');
      await tester.pumpAndSettle();

      expect(find.text('PRODUCT MATCHES'), findsOneWidget);
      expect(find.byType(SearchSuggestionRow), findsWidgets);
    });

    testWidgets('4. Tapping clear button (x) clears query and returns to empty query suggestions',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(
        localStorage: localStorage,
        initialQuery: 'apple',
      ));
      await tester.pumpAndSettle();

      final clearBtn = find.byKey(const Key('search_clear_button'));
      expect(clearBtn, findsOneWidget);

      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.text('POPULAR SEARCHES'), findsOneWidget);
    });

    testWidgets('5. Tapping a PRODUCT MATCH row updates search query and submits search to results grid without modifying cart',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(
        localStorage: localStorage,
        initialQuery: 'gala',
      ));
      await tester.pumpAndSettle();

      // Tap the first suggestion row
      final firstRow = find.byType(SearchSuggestionRow).first;
      expect(firstRow, findsOneWidget);
      await tester.tap(firstRow);
      await tester.pumpAndSettle();

      // Should transition to Screen 18 Search Results Grid with 2-column AppProductCard
      expect(find.byType(AppProductCard), findsWidgets);
      expect(find.textContaining('Showing'), findsOneWidget);
      expect(find.textContaining('Apple — Fresh Royal Gala'), findsWidgets);

      // Cart should NOT have been modified by autocomplete selection
      expect(find.byType(CheckoutBar), findsNothing);
    });

    testWidgets('5b. Tapping a SEARCH SUGGESTION item updates query and transitions to results grid',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(
        localStorage: localStorage,
        initialQuery: 'apple',
      ));
      await tester.pumpAndSettle();

      // Find the first query suggestion item
      final suggestionItem = find.byType(SearchQuerySuggestionItem).first;
      expect(suggestionItem, findsOneWidget);
      await tester.tap(suggestionItem);
      await tester.pumpAndSettle();

      // Should transition to Screen 18 Results
      expect(find.textContaining('Showing'), findsOneWidget);
      expect(find.byType(AppProductCard), findsWidgets);
    });

    testWidgets('6. Submitting search query transitions to Screen 18 — Search Results grid',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'apple');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Screen 18 Results Grid & Meta Bar (3 in-stock apples, out-of-stock apple omitted)
      expect(find.byType(AppProductCard), findsNWidgets(3));
      expect(find.textContaining('Showing'), findsOneWidget);
      expect(find.textContaining('3 products'), findsOneWidget);
    });

    testWidgets('7. In-stock product card opens Product Details screen',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      String? selectedProductId;

      final router = GoRouter(
        initialLocation: '/search',
        routes: [
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
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

      await tester.pumpWidget(_createSearchTestWidget(
        localStorage: localStorage,
        customRouter: router,
      ));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'gala');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      final productCard = find.byType(AppProductCard).first;
      expect(productCard, findsOneWidget);
      await tester.tap(productCard);
      await tester.pumpAndSettle();

      expect(selectedProductId, equals('p_apple_gala'));
      expect(find.text('Details for p_apple_gala'), findsOneWidget);
    });

    testWidgets('8. Out-of-stock product does not appear in search results',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'honeycrisp');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Honeycrisp is out of stock so it does not appear in results
      expect(find.text('Organic Honeycrisp Apple'), findsNothing);
      expect(find.text('No products found'), findsOneWidget);
    });

    testWidgets('9. Submitting query with no matches transitions to Screen 19 — Search No Results',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'dragon fruit');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byType(SearchNoResultsCard), findsOneWidget);
      expect(find.text('No products found'), findsOneWidget);
      expect(find.text('Search Again'), findsOneWidget);
    });

    testWidgets('10. Screen 19 "Search Again" button resets query and focuses search field',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'dragon fruit');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      final searchAgainBtn = find.text('Search Again');
      expect(searchAgainBtn, findsOneWidget);

      await tester.tap(searchAgainBtn);
      await tester.pumpAndSettle();

      expect(find.text('POPULAR SEARCHES'), findsOneWidget);
    });

    testWidgets('11. Checkout button on CheckoutBar routes to /checkout',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      bool navigatedToCheckout = false;

      final router = GoRouter(
        initialLocation: '/search',
        routes: [
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/checkout',
            builder: (context, state) {
              navigatedToCheckout = true;
              return const Scaffold(body: Text('Checkout Screen Destination'));
            },
          ),
        ],
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(
        localStorage: localStorage,
        initialCart: {'p_apple_gala': 2},
        customRouter: router,
      ));
      await tester.pumpAndSettle();

      final checkoutBtn = find.text('Checkout');
      expect(checkoutBtn, findsOneWidget);

      await tester.tap(checkoutBtn);
      await tester.pumpAndSettle();

      expect(navigatedToCheckout, isTrue);
    });

    testWidgets('12. Dark theme renders correctly without crash', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(
        localStorage: localStorage,
        themeMode: ThemeMode.dark,
        initialQuery: 'apple',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('13. Responsive layout on small and large phones without overflow',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      // Small screen: 320 x 568
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(_createSearchTestWidget(
        localStorage: localStorage,
        initialQuery: 'apple',
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Large screen: 430 x 932
      tester.view.physicalSize = const Size(430 * 3, 932 * 3);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(_createSearchTestWidget(
        localStorage: localStorage,
        initialQuery: 'apple',
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. Global Search results gridDelegate uses deterministic mainAxisExtent matching Category Listing',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createSearchTestWidget(
        localStorage: localStorage,
      ));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'apple');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final gridWidget = tester.widget<GridView>(gridFinder);
      final delegate = gridWidget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, equals(2));
      expect(delegate.crossAxisSpacing, equals(12.0));
      expect(delegate.mainAxisSpacing, equals(14.0));
      expect(delegate.mainAxisExtent, equals(112.0 + 108.0));

      // AppProductCards inside grid
      expect(find.byType(AppProductCard), findsWidgets);
    });
  });
}
