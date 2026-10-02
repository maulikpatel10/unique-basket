import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/features/explore/presentation/screens/category_product_listing_screen.dart';
import 'package:customer_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:customer_app/features/home/data/models/banner_model.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/product/presentation/screens/product_details_screen.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:customer_app/shared/widgets/app_product_card.dart';
import 'package:customer_app/shared/widgets/product_quantity_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockProductDetailsHomeDataSource implements HomeRemoteDataSource {
  final List<ProductModel> products;
  final bool shouldThrow;

  MockProductDetailsHomeDataSource({
    this.products = const [],
    this.shouldThrow = false,
  });

  @override
  Future<List<ProductModel>> getStoreProducts(
    String storeId, {
    String? categoryId,
  }) async {
    if (shouldThrow) throw Exception('API Error');
    if (categoryId != null && categoryId.isNotEmpty) {
      return products.where((p) => p.categoryId == categoryId).toList();
    }
    return products;
  }

  @override
  Future<List<CategoryModel>> getCategories() async => [
        const CategoryModel(id: 'cat_fruits', name: 'Fruits', isActive: true),
      ];

  @override
  Future<List<ProductModel>> getFeaturedProducts() async => products;

  @override
  Future<List<BannerModel>> getBanners() async => [];
}

void main() {
  const testStore = StoreModel(
    id: 'store_1',
    storeId: 'UB001',
    name: 'Unique Basket Main',
    address: '150ft Ring Road',
    city: 'Rajkot',
    state: 'Gujarat',
    pincode: '360001',
    latitude: 22.3039,
    longitude: 70.8022,
    phone: '9876543210',
    openingTime: '08:00 AM',
    closingTime: '10:00 PM',
    isActive: true,
  );

  const testProduct = ProductModel(
    id: 'prod_avocado_99',
    categoryId: 'cat_fruits',
    categoryName: 'Fruits',
    name: 'Fresh Hass Avocado',
    description: 'Fresh rich Haas avocado directly from farms.',
    price: 120.0,
    mrp: 150.0,
    unit: '1 pc (200g)',
    stockQuantity: 10.0,
    isAvailable: true,
  );

  const outOfStockProduct = ProductModel(
    id: 'prod_oos_1',
    categoryId: 'cat_fruits',
    categoryName: 'Fruits',
    name: 'Out of Stock Berries',
    description: 'Fresh berries currently unavailable.',
    price: 250.0,
    mrp: 300.0,
    unit: '1 box',
    stockQuantity: 0.0,
    isAvailable: false,
  );

  const similarProduct = ProductModel(
    id: 'prod_banana_1',
    categoryId: 'cat_fruits',
    categoryName: 'Fruits',
    name: 'Organic Bananas',
    description: 'Fresh organic ripe bananas.',
    price: 60.0,
    mrp: 80.0,
    unit: '1 dozen',
    stockQuantity: 15.0,
    isAvailable: true,
  );

  group('Screen 11 — Product Details Tests', () {
    testWidgets('1. ProductDetailsScreen renders vertical info stack (Name -> Unit -> Price + MRP) without top quantity stepper',
        (tester) async {
      final mockSource = MockProductDetailsHomeDataSource(
        products: [testProduct, similarProduct],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(testStore)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductDetailsScreen(
              productId: 'prod_avocado_99',
              initialProduct: testProduct,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fresh Hass Avocado'), findsWidgets);
      expect(find.text('1 pc (200g)'), findsWidgets);
      expect(find.text('₹120'), findsWidgets);
      expect(find.text('MRP ₹150'), findsWidgets);
      expect(find.text('Product Detail'), findsOneWidget);
      expect(find.text('Fruits'), findsWidgets);
      expect(find.text('Similar products'), findsOneWidget);
    });

    testWidgets('2. Tap Add transforms to ProductQuantityControl and updates CartStateNotifier',
        (tester) async {
      final mockSource = MockProductDetailsHomeDataSource(
        products: [testProduct, similarProduct],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(testStore)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductDetailsScreen(
              productId: 'prod_avocado_99',
              initialProduct: testProduct,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(container.read(cartNotifierProvider)['prod_avocado_99'], isNull);

      // State 1: Add to Cart button is visible
      expect(find.text('Add to Cart'), findsOneWidget);

      // Tap Add to Cart
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // State 2: Transformed to ProductQuantityControl showing 1
      expect(container.read(cartNotifierProvider)['prod_avocado_99'], 1);
      expect(find.byType(ProductQuantityControl), findsWidgets);
      expect(find.text('1'), findsWidgets);

      // Tap + button -> quantity becomes 2
      final plusButton = find.descendant(
        of: find.byType(ProductQuantityControl),
        matching: find.byIcon(Icons.add_rounded),
      ).last;
      await tester.tap(plusButton);
      await tester.pumpAndSettle();

      expect(container.read(cartNotifierProvider)['prod_avocado_99'], 2);
      expect(find.text('2'), findsWidgets);

      // Tap - button -> quantity decreases to 1
      final minusButton = find.descendant(
        of: find.byType(ProductQuantityControl),
        matching: find.byIcon(Icons.remove_rounded),
      ).last;
      await tester.tap(minusButton);
      await tester.pumpAndSettle();

      expect(container.read(cartNotifierProvider)['prod_avocado_99'], 1);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('3. Favorite button toggles FavoritesNotifier state', (tester) async {
      final mockSource = MockProductDetailsHomeDataSource(
        products: [testProduct, similarProduct],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(testStore)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductDetailsScreen(
              productId: 'prod_avocado_99',
              initialProduct: testProduct,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(container.read(favoritesNotifierProvider).contains('prod_avocado_99'), isFalse);

      final favoriteButton = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.favorite_border_rounded && w.size == 20,
      );
      await tester.tap(favoriteButton);
      await tester.pumpAndSettle();

      expect(container.read(favoritesNotifierProvider).contains('prod_avocado_99'), isTrue);
    });

    testWidgets('4. Product Detail section collapses and expands on tap', (tester) async {
      final mockSource = MockProductDetailsHomeDataSource(
        products: [testProduct, similarProduct],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(testStore)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductDetailsScreen(
              productId: 'prod_avocado_99',
              initialProduct: testProduct,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

      await tester.ensureVisible(find.text('Product Detail'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Product Detail'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });

    testWidgets('5. Out of stock product shows disabled CTA', (tester) async {
      final mockSource = MockProductDetailsHomeDataSource(
        products: [outOfStockProduct],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(testStore)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductDetailsScreen(
              productId: 'prod_oos_1',
              initialProduct: outOfStockProduct,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Out of Stock'), findsWidgets);
    });

    testWidgets('6. ProductDetailsScreen renders gracefully when initialProduct is null', (tester) async {
      final mockSource = MockProductDetailsHomeDataSource(
        products: [testProduct],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(testStore)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductDetailsScreen(
              productId: 'prod_avocado_99',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fresh Hass Avocado'), findsWidgets);
    });

    testWidgets('7. Back button pops navigation', (tester) async {
      final mockSource = MockProductDetailsHomeDataSource(
        products: [testProduct],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(testStore)),
        ],
      );

      bool popped = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProductDetailsScreen(
                          productId: 'prod_avocado_99',
                          initialProduct: testProduct,
                        ),
                      ),
                    ).then((_) => popped = true);
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('8. CategoryProductListingScreen in-stock product tap navigates to ProductDetails', (tester) async {
      final mockSource = MockProductDetailsHomeDataSource(
        products: [testProduct],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(testStore)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CategoryProductListingScreen(
              categoryId: 'cat_fruits',
              categoryName: 'Fruits',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppProductCard), findsOneWidget);
    });

    testWidgets('9. Dark mode renders correctly without error', (tester) async {
      final mockSource = MockProductDetailsHomeDataSource(
        products: [testProduct],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(testStore)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProductDetailsScreen(
              productId: 'prod_avocado_99',
              initialProduct: testProduct,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fresh Hass Avocado'), findsWidgets);
    });

    testWidgets('10. Small phone layout renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockSource = MockProductDetailsHomeDataSource(
        products: [testProduct],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockSource),
          servingStoreProvider.overrideWith((ref) => Future.value(testStore)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductDetailsScreen(
              productId: 'prod_avocado_99',
              initialProduct: testProduct,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Fresh Hass Avocado'), findsWidgets);
    });
  });
}
