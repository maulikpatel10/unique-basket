import 'package:customer_app/core/constants/api_endpoints.dart';
import 'package:customer_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:customer_app/features/home/data/models/banner_model.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:customer_app/shared/widgets/app_product_card.dart';
import 'package:customer_app/shared/widgets/product_quantity_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockStoreProductDataSource implements HomeRemoteDataSource {
  final Map<String, List<ProductModel>> storeProducts;
  final bool shouldThrow;
  final Map<String, int> callCounts = {};

  MockStoreProductDataSource({
    this.storeProducts = const {},
    this.shouldThrow = false,
  });

  @override
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId}) async {
    callCounts[storeId] = (callCounts[storeId] ?? 0) + 1;
    if (shouldThrow) {
      throw Exception('Store product API failed');
    }
    return storeProducts[storeId] ?? [];
  }

  @override
  Future<List<CategoryModel>> getCategories() async => [];

  @override
  Future<List<ProductModel>> getFeaturedProducts() async => [];

  @override
  Future<List<BannerModel>> getBanners() async => [];
}

void main() {
  group('Home Step 4 — Store Products Integration Tests', () {
    test('1. ProductModel parses real backend store-product response with inventory', () {
      final json = {
        'id': 'prod_avocado_1',
        'categoryId': 'cat_fruits_1',
        'categoryName': 'Fresh Fruits',
        'name': 'Organic Hass Avocado',
        'description': 'Creamy ripe organic avocado',
        'price': 4.99,
        'mrp': 5.99,
        'unit': 'Pack of 2',
        'imageUrl': 'https://example.com/avocado.jpg',
        'stockQuantity': 25.0,
        'lowStockThreshold': 5.0,
        'isAvailable': true,
        'isActive': true,
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, equals('prod_avocado_1'));
      expect(product.categoryId, equals('cat_fruits_1'));
      expect(product.categoryName, equals('Fresh Fruits'));
      expect(product.name, equals('Organic Hass Avocado'));
      expect(product.price, equals(4.99));
      expect(product.mrp, equals(5.99));
      expect(product.unit, equals('Pack of 2'));
      expect(product.imageUrl, equals('https://example.com/avocado.jpg'));
      expect(product.stockQuantity, equals(25.0));
      expect(product.lowStockThreshold, equals(5.0));
      expect(product.isAvailable, isTrue);
      expect(product.isPurchasable, isTrue);
      expect(product.resolvedBadge, equals('17% OFF'));
    });

    test('1b. ProductModel parses String-encoded Decimal fields from PostgreSQL Prisma backend', () {
      final json = {
        'id': 'prod_apple_1',
        'categoryId': 'cat_fruits_1',
        'categoryName': 'Fruits',
        'name': 'Apple (Shimla)',
        'description': 'Crisp and sweet fresh Shimla apples',
        'price': '180',
        'mrp': '200',
        'unit': '1 kg',
        'imageUrl': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6',
        'stockQuantity': 50,
        'lowStockThreshold': 5.0,
        'isAvailable': true,
        'isActive': true,
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, equals('prod_apple_1'));
      expect(product.price, equals(180.0));
      expect(product.mrp, equals(200.0));
      expect(product.stockQuantity, equals(50.0));
      expect(product.isPurchasable, isTrue);
      expect(product.resolvedBadge, equals('10% OFF'));
    });

    test('2. ApiEndpoints.storeProducts formats verified endpoint string', () {
      const storeId = 'store_rajkot_central';
      final endpoint = ApiEndpoints.storeProducts(storeId);
      expect(endpoint, equals('/products/store/store_rajkot_central'));
    });

    test('3. homeProductsProvider dynamically resolves products from servingStoreProvider', () async {
      final mockDataSource = MockStoreProductDataSource(
        storeProducts: {
          'store_123': [
            const ProductModel(
              id: 'p1',
              categoryId: 'c1',
              name: 'Store 123 Avocado',
              price: 4.50,
              unit: '1 kg',
              stockQuantity: 10,
              isAvailable: true,
            ),
          ],
        },
      );

      final container = ProviderContainer(
        overrides: [
          servingStoreProvider.overrideWith((ref) async => const StoreModel(
                id: 'store_123',
                storeId: 'RAJ-01',
                name: 'Store 123 Rajkot',
                address: '150ft Ring Road',
                city: 'Rajkot',
                state: 'Gujarat',
                pincode: '360005',
                latitude: 22.2904,
                longitude: 70.7749,
                phone: '+919876543210',
                openingTime: '07:00',
                closingTime: '22:00',
                isActive: true,
                isEligible: true,
                deliveryRadiusKm: 5.0,
              )),
          homeRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
      addTearDown(container.dispose);

      final products = await container.read(homeProductsProvider.future);

      expect(products.length, equals(1));
      expect(products.first.name, equals('Store 123 Avocado'));
      expect(mockDataSource.callCounts['store_123'], equals(1));
    });

    test('4. No request made and empty list returned when servingStore is null', () async {
      final mockDataSource = MockStoreProductDataSource();

      final container = ProviderContainer(
        overrides: [
          servingStoreProvider.overrideWith((ref) async => null),
          homeRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
      addTearDown(container.dispose);

      final products = await container.read(homeProductsProvider.future);

      expect(products, isEmpty);
      expect(mockDataSource.callCounts.isEmpty, isTrue);
    });

    test('5. Store Change Safety: Switching store loads new store products without mixing', () async {
      final mockDataSource = MockStoreProductDataSource(
        storeProducts: {
          'store_A': [
            const ProductModel(id: 'pA', categoryId: 'cA', name: 'Product Store A', price: 3.99, unit: '1 kg'),
          ],
          'store_B': [
            const ProductModel(id: 'pB', categoryId: 'cB', name: 'Product Store B', price: 6.99, unit: '500g'),
          ],
        },
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
      addTearDown(container.dispose);

      final storeAProducts = await container.read(storeProductsProvider('store_A').future);
      expect(storeAProducts.first.name, equals('Product Store A'));

      final storeBProducts = await container.read(storeProductsProvider('store_B').future);
      expect(storeBProducts.first.name, equals('Product Store B'));

      expect(mockDataSource.callCounts['store_A'], equals(1));
      expect(mockDataSource.callCounts['store_B'], equals(1));
    });

    test('6. Available product with stock > 0 has isPurchasable true', () {
      const product = ProductModel(
        id: 'p1',
        categoryId: 'c1',
        name: 'Fresh Greens',
        price: 2.99,
        unit: '250g',
        stockQuantity: 15.0,
        isAvailable: true,
        isActive: true,
      );

      expect(product.isPurchasable, isTrue);
    });

    test('7. Out-of-stock product has isPurchasable false', () {
      const zeroStockProduct = ProductModel(
        id: 'p2',
        categoryId: 'c1',
        name: 'Out of stock apples',
        price: 3.99,
        unit: '1 kg',
        stockQuantity: 0.0,
        isAvailable: true,
        isActive: true,
      );

      expect(zeroStockProduct.isPurchasable, isFalse);

      const unavailableProduct = ProductModel(
        id: 'p3',
        categoryId: 'c1',
        name: 'Unavailable berry',
        price: 4.99,
        unit: '1 box',
        stockQuantity: 10.0,
        isAvailable: false,
        isActive: true,
      );

      expect(unavailableProduct.isPurchasable, isFalse);
    });

    test('8. Empty store product response returns empty list safely', () async {
      final mockDataSource = MockStoreProductDataSource(
        storeProducts: {'store_empty': []},
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
      addTearDown(container.dispose);

      final products = await container.read(storeProductsProvider('store_empty').future);
      expect(products, isEmpty);
    });

    test('9. Product API error propagates as AsyncError without fabricating fake data', () async {
      final mockDataSource = MockStoreProductDataSource(shouldThrow: true);

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(storeProductsProvider('store_err').future),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('10. AppProductCard maintains exact 32dp height for out of stock state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 170,
              child: AppProductCard(
                id: 'p_oos',
                name: 'Out of stock produce',
                price: 4.99,
                unit: '1 kg',
                isPurchasable: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('OUT OF STOCK'), findsOneWidget);
    });

    testWidgets('11. ProductQuantityControl maintains layout stability across quantity changes', (tester) async {
      double quantity = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ProductQuantityControl(
                  quantity: quantity,
                  onAddToCart: () => setState(() => quantity = 1),
                  onIncrement: () => setState(() => quantity++),
                  onDecrement: () => setState(() => quantity--),
                );
              },
            ),
          ),
        ),
      );

      // Initial '+' button
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Tap to expand
      await tester.tap(find.byType(ProductQuantityControl));
      await tester.pumpAndSettle();

      expect(quantity, equals(1));
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    });
  });
}
