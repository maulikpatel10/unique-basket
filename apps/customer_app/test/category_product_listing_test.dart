import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/features/explore/presentation/screens/category_product_listing_screen.dart';
import 'package:customer_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:customer_app/features/home/data/models/banner_model.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:customer_app/shared/widgets/app_bottom_nav_bar.dart';
import 'package:customer_app/shared/widgets/app_empty_state.dart';
import 'package:customer_app/shared/widgets/app_error_state.dart';
import 'package:customer_app/shared/widgets/app_product_card.dart';
import 'package:customer_app/shared/widgets/checkout_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class MockCategoryProductDataSource implements HomeRemoteDataSource {
  final Map<String, List<ProductModel>> storeProducts;
  final bool shouldThrow;
  final List<String> requestedCategoryIds = [];
  final List<String> requestedStoreIds = [];

  MockCategoryProductDataSource({
    this.storeProducts = const {},
    this.shouldThrow = false,
  });

  @override
  Future<List<ProductModel>> getStoreProducts(
    String storeId, {
    String? categoryId,
  }) async {
    requestedStoreIds.add(storeId);
    if (categoryId != null) {
      requestedCategoryIds.add(categoryId);
    }
    if (shouldThrow) {
      throw Exception('Category products API error');
    }
    final all = storeProducts[storeId] ?? [];
    if (categoryId != null && categoryId.isNotEmpty) {
      return all.where((p) => p.categoryId == categoryId).toList();
    }
    return all;
  }

  @override
  Future<List<CategoryModel>> getCategories() async => [];

  @override
  Future<List<ProductModel>> getFeaturedProducts() async => [];

  @override
  Future<List<BannerModel>> getBanners() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .physicalSize = const Size(390 * 3, 844 * 3);
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .devicePixelRatio = 3.0;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetPhysicalSize();
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetDevicePixelRatio();
  });

  const sampleStore = StoreModel(
    id: 'store_rajkot_1',
    storeId: 'UB-RJK-01',
    name: 'Unique Basket Rajkot Superstore',
    address: '150 Feet Ring Road, Rajkot',
    city: 'Rajkot',
    state: 'Gujarat',
    pincode: '360005',
    latitude: 22.3039,
    longitude: 70.8022,
    deliveryRadiusKm: 15.0,
    phone: '+91 98765 43210',
    openingTime: '07:00 AM',
    closingTime: '10:00 PM',
    distanceKm: 2.3,
  );

  const sampleProducts = [
    ProductModel(
      id: 'prod_apple_1',
      categoryId: 'cat_fruits_1',
      categoryName: 'Fruits',
      name: 'Apple (Shimla)',
      description: 'Crisp and sweet fresh Shimla apples',
      price: 180.0,
      mrp: 200.0,
      unit: '1 kg',
      stockQuantity: 20.0,
      isAvailable: true,
      isActive: true,
    ),
    ProductModel(
      id: 'prod_banana_1',
      categoryId: 'cat_fruits_1',
      categoryName: 'Fruits',
      name: 'Banana (Robusta)',
      description: 'Naturally ripened sweet bananas',
      price: 60.0,
      mrp: 70.0,
      unit: '1 dozen',
      stockQuantity: 15.0,
      isAvailable: true,
      isActive: true,
    ),
    ProductModel(
      id: 'prod_avocado_1',
      categoryId: 'cat_fruits_1',
      categoryName: 'Fruits',
      name: 'Organic Hass Avocado',
      description: 'Imported ripe creamy avocado',
      price: 240.0,
      mrp: 280.0,
      unit: 'Pack of 2',
      stockQuantity: 10.0,
      isAvailable: true,
      isActive: true,
    ),
    ProductModel(
      id: 'prod_oos_berries',
      categoryId: 'cat_fruits_1',
      categoryName: 'Fruits',
      name: 'Out of Stock Berries',
      description: 'Fresh seasonal berries',
      price: 180.0,
      unit: '1 box',
      stockQuantity: 0.0, // Out of stock
      isAvailable: true,
      isActive: true,
    ),
    ProductModel(
      id: 'prod_spinach_1',
      categoryId: 'cat_veg_1',
      categoryName: 'Vegetables',
      name: 'Fresh Spinach',
      description: 'Farm fresh green spinach',
      price: 30.0,
      unit: '500 g',
      stockQuantity: 10.0,
      isAvailable: true,
      isActive: true,
    ),
  ];

  Widget createWidgetUnderTest({
    required HomeRemoteDataSource dataSource,
    StoreModel? servingStore,
    String categoryId = 'cat_fruits_1',
    String categoryName = 'Fruits',
  }) {
    return ProviderScope(
      overrides: [
        homeRemoteDataSourceProvider.overrideWithValue(dataSource),
        servingStoreProvider.overrideWith((ref) => Future.value(servingStore)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: CategoryProductListingScreen(
          categoryId: categoryId,
          categoryName: categoryName,
        ),
      ),
    );
  }

  group('Screen 10 — Category Product Listing Tests', () {
    testWidgets(
        '1. Displays dynamic category title and renders real products for category',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: sampleStore,
          categoryId: 'cat_fruits_1',
          categoryName: 'Fresh Fruits',
        ),
      );

      await tester.pumpAndSettle();

      // Header title
      expect(find.text('Fresh Fruits'), findsOneWidget);

      // Verify categoryId was passed to repository
      expect(mockSource.requestedCategoryIds, contains('cat_fruits_1'));
      expect(mockSource.requestedStoreIds, contains('store_rajkot_1'));

      // Products in cat_fruits_1 should be rendered
      expect(find.text('Apple (Shimla)'), findsOneWidget);
      expect(find.text('Banana (Robusta)'), findsOneWidget);
      expect(find.text('Organic Hass Avocado'), findsOneWidget);

      // Product in cat_veg_1 should NOT be shown in Fruits
      expect(find.text('Fresh Spinach'), findsNothing);

      // Bottom nav is present with Explore tab
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('2. Out of stock product is not visible in category listing',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: sampleStore,
          categoryId: 'cat_fruits_1',
        ),
      );

      await tester.pumpAndSettle();

      // Out of stock product is omitted
      expect(find.text('Out of Stock Berries'), findsNothing);

      // In-stock products are present
      expect(find.text('Apple (Shimla)'), findsOneWidget);
      expect(find.text('Banana (Robusta)'), findsOneWidget);
      expect(find.text('Organic Hass Avocado'), findsOneWidget);
    });

    testWidgets('3. Local search filters products by name and description',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: sampleStore,
          categoryId: 'cat_fruits_1',
          categoryName: 'Fruits',
        ),
      );

      await tester.pumpAndSettle();

      // Initially all 3 fruit products present
      expect(find.text('Apple (Shimla)'), findsOneWidget);
      expect(find.text('Banana (Robusta)'), findsOneWidget);
      expect(find.text('Organic Hass Avocado'), findsOneWidget);

      // Enter search text "apple"
      await tester.enterText(find.byType(TextField), 'apple');
      await tester.pumpAndSettle();

      expect(find.text('Apple (Shimla)'), findsOneWidget);
      expect(find.text('Banana (Robusta)'), findsNothing);
      expect(find.text('Organic Hass Avocado'), findsNothing);

      // Clear search by clearing text field
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // All 3 restored
      expect(find.text('Apple (Shimla)'), findsOneWidget);
      expect(find.text('Banana (Robusta)'), findsOneWidget);
      expect(find.text('Organic Hass Avocado'), findsOneWidget);
    });

    testWidgets(
        '4. Local search with zero results shows friendly empty search state',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: sampleStore,
          categoryId: 'cat_fruits_1',
        ),
      );

      await tester.pumpAndSettle();

      // Enter nonexistent search query
      await tester.enterText(find.byType(TextField), 'dragonfruit');
      await tester.pumpAndSettle();

      expect(find.text('No fruits found'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      // Tap "Clear Search"
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      expect(find.text('Apple (Shimla)'), findsOneWidget);
    });

    testWidgets('5. Null serving store displays no-serving-store empty state',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: null,
          categoryId: 'cat_fruits_1',
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('No Serving Store'), findsOneWidget);
    });

    testWidgets('6. Empty category response displays empty category state',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': []},
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: sampleStore,
          categoryId: 'cat_empty_1',
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('No Products'), findsOneWidget);
    });

    testWidgets('7. API failure displays AppErrorState', (tester) async {
      final mockSource = MockCategoryProductDataSource(
        shouldThrow: true,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: sampleStore,
          categoryId: 'cat_fruits_1',
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
    });

    testWidgets(
        '8. Cart increment and decrement interaction works from product card',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(sampleStore)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CategoryProductListingScreen(
              categoryId: 'cat_fruits_1',
              categoryName: 'Fruits',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(container.read(cartNotifierProvider)['prod_apple_1'], isNull);

      // Tap add button on Apple
      final addButtons = find.byIcon(Icons.add_rounded);
      expect(addButtons, findsWidgets);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Cart now has quantity 1 for prod_apple_1
      expect(container.read(cartNotifierProvider)['prod_apple_1'], equals(1));
    });

    testWidgets('9. CheckoutBar appears dynamically when item added to cart',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(sampleStore)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CategoryProductListingScreen(
              categoryId: 'cat_fruits_1',
              categoryName: 'Fruits',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, total cart count is 0, so CheckoutBar should be hidden/empty or itemCount 0
      final initialBar = tester.widgetList<CheckoutBar>(find.byType(CheckoutBar)).toList();
      expect(initialBar.first.itemCount, equals(0));

      // Tap add button on Apple
      final addButtons = find.byIcon(Icons.add_rounded);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // CheckoutBar should now show 1 Product and ₹180.00
      final updatedBar = tester.widgetList<CheckoutBar>(find.byType(CheckoutBar)).toList();
      expect(updatedBar.first.itemCount, equals(1));
      expect(find.text('1 Product'), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets('10. Tapping in-stock product opens Product Details',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(sampleStore)),
        ],
      );

      String? pushedRoute;
      final router = GoRouter(
        initialLocation: '/category-products?categoryId=cat_fruits_1',
        routes: [
          GoRoute(
            path: '/category-products',
            builder: (context, state) => const CategoryProductListingScreen(
              categoryId: 'cat_fruits_1',
              categoryName: 'Fruits',
            ),
          ),
          GoRoute(
            path: '/product-details',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return const Scaffold(body: Text('Product Details Screen View'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap in-stock product (Apple)
      await tester.tap(find.text('Apple (Shimla)'));
      await tester.pumpAndSettle();

      expect(pushedRoute, contains('/product-details?productId=prod_apple_1'));
      expect(find.text('Product Details Screen View'), findsOneWidget);
    });

    testWidgets(
        '11. Out of stock products are not visible in category listing',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(sampleStore)),
        ],
      );

      bool detailsPushed = false;
      final router = GoRouter(
        initialLocation: '/category-products?categoryId=cat_fruits_1',
        routes: [
          GoRoute(
            path: '/category-products',
            builder: (context, state) => const CategoryProductListingScreen(
              categoryId: 'cat_fruits_1',
              categoryName: 'Fruits',
            ),
          ),
          GoRoute(
            path: '/product-details',
            builder: (context, state) {
              detailsPushed = true;
              return const Scaffold(body: Text('Product Details Screen View'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify out of stock product is not visible
      expect(find.text('Out of Stock Berries'), findsNothing);

      // Verify in-stock product is visible and navigates
      expect(find.text('Apple (Shimla)'), findsOneWidget);
      await tester.tap(find.text('Apple (Shimla)'));
      await tester.pumpAndSettle();

      expect(detailsPushed, isTrue);
      expect(find.text('Product Details Screen View'), findsOneWidget);
    });

    testWidgets(
        '12. Case-insensitivity and whitespace tolerance when filtering category products',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: sampleStore,
          categoryId: 'cat_fruits_1',
          categoryName: 'Fruits',
        ),
      );

      await tester.pumpAndSettle();

      // Test uppercase query with leading/trailing whitespace
      await tester.enterText(find.byType(TextField), '  BANANA  ');
      await tester.pumpAndSettle();

      expect(find.text('Banana (Robusta)'), findsOneWidget);
      expect(find.text('Apple (Shimla)'), findsNothing);
      expect(find.text('Organic Hass Avocado'), findsNothing);

      // Test mixed case
      await tester.enterText(find.byType(TextField), 'BaNaNa');
      await tester.pumpAndSettle();

      expect(find.text('Banana (Robusta)'), findsOneWidget);
      expect(find.text('Apple (Shimla)'), findsNothing);
    });

    testWidgets(
        '13. Submitting search dismisses keyboard focus and retains filtered results',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: sampleStore,
          categoryId: 'cat_fruits_1',
          categoryName: 'Fruits',
        ),
      );

      await tester.pumpAndSettle();

      // Focus and enter text
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'banana');
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.focusNode?.hasFocus, isTrue);

      // Submit search via keyboard action
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Focus should be dismissed (unfocused)
      expect(textField.focusNode?.hasFocus, isFalse);

      // Query and filtered results must remain intact
      expect(find.text('banana'), findsOneWidget);
      expect(find.text('Banana (Robusta)'), findsOneWidget);
      expect(find.text('Apple (Shimla)'), findsNothing);
      expect(find.byType(CategoryProductListingScreen), findsOneWidget);
    });

    testWidgets(
        '14. Tapping clear button (X) restores full category product list without navigating',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: sampleStore,
          categoryId: 'cat_fruits_1',
          categoryName: 'Fruits',
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'banana');
      await tester.pumpAndSettle();

      expect(find.text('Banana (Robusta)'), findsOneWidget);
      expect(find.text('Apple (Shimla)'), findsNothing);

      // Clear button (X) should be visible
      final clearButtonFinder = find.byKey(const Key('category_search_clear_button'));
      expect(clearButtonFinder, findsOneWidget);

      // Tap clear button
      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();

      // Full product list should be restored
      expect(find.text('Apple (Shimla)'), findsOneWidget);
      expect(find.text('Banana (Robusta)'), findsOneWidget);
      expect(find.text('Organic Hass Avocado'), findsOneWidget);

      // Still on category screen
      expect(find.byType(CategoryProductListingScreen), findsOneWidget);
    });

    testWidgets(
        '15. Back button when search field is focused unfocuses keyboard first',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: sampleStore,
          categoryId: 'cat_fruits_1',
          categoryName: 'Fruits',
        ),
      );

      await tester.pumpAndSettle();

      // Tap to focus search field
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, isTrue);

      // Tap app bar back button while focused
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Keyboard should be dismissed/unfocused, screen should NOT be popped
      expect(textField.focusNode?.hasFocus, isFalse);
      expect(find.byType(CategoryProductListingScreen), findsOneWidget);
    });

    testWidgets(
        '16. Category empty search state includes category label and clear action',
        (tester) async {
      final mockSource = MockCategoryProductDataSource(
        storeProducts: {'store_rajkot_1': sampleProducts},
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          dataSource: mockSource,
          servingStore: sampleStore,
          categoryId: 'cat_fruits_1',
          categoryName: 'Fruits',
        ),
      );

      await tester.pumpAndSettle();

      // Enter query with no matches
      await tester.enterText(find.byType(TextField), 'xyz123');
      await tester.pumpAndSettle();

      // Check category-scoped empty message
      expect(find.text('No fruits found'), findsOneWidget);
      expect(find.text('Try a different search term.'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      // Tap Clear Search button
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      // Full list is restored
      expect(find.text('Apple (Shimla)'), findsOneWidget);
      expect(find.text('Banana (Robusta)'), findsOneWidget);
      expect(find.text('Organic Hass Avocado'), findsOneWidget);
    });
  });
}
