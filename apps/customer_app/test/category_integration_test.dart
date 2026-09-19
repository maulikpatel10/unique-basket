import 'package:customer_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:customer_app/features/home/data/models/banner_model.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHomeRemoteDataSource implements HomeRemoteDataSource {
  final List<CategoryModel> categories;
  final bool shouldThrow;
  int callCount = 0;

  MockHomeRemoteDataSource({
    this.categories = const [],
    this.shouldThrow = false,
  });

  @override
  Future<List<CategoryModel>> getCategories() async {
    callCount++;
    if (shouldThrow) {
      throw Exception('Category API failed');
    }
    return categories;
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts() async => [];

  @override
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId}) async => [];

  @override
  Future<List<BannerModel>> getBanners() async => [];
}

void main() {
  group('Category Integration Layer Tests', () {
    test('1. CategoryModel.fromJson parses backend Category schema accurately', () {
      final json = {
        'id': 'b15093f4-1234-4567-89ab-cdef01234567',
        'name': 'Fresh Produce',
        'description': 'Farm fresh fruits and organic vegetables',
        'imageUrl': 'https://example.com/images/fresh_produce.jpg',
        'displayOrder': 1,
        'isActive': true,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };

      final category = CategoryModel.fromJson(json);

      expect(category.id, equals('b15093f4-1234-4567-89ab-cdef01234567'));
      expect(category.name, equals('Fresh Produce'));
      expect(category.description, equals('Farm fresh fruits and organic vegetables'));
      expect(category.imageUrl, equals('https://example.com/images/fresh_produce.jpg'));
      expect(category.displayOrder, equals(1));
      expect(category.isActive, isTrue);
    });

    test('2. CategoryModel handles snake_case keys if returned by raw DB queries', () {
      final json = {
        'id': 'cat_veg',
        'name': 'Vegetables',
        'image_url': 'https://example.com/images/veg.jpg',
        'display_order': 2,
        'is_active': true,
      };

      final category = CategoryModel.fromJson(json);

      expect(category.id, equals('cat_veg'));
      expect(category.name, equals('Vegetables'));
      expect(category.imageUrl, equals('https://example.com/images/veg.jpg'));
      expect(category.displayOrder, equals(2));
      expect(category.isActive, isTrue);
    });

    test('3. homeCategoriesProvider returns categories from HomeRepository', () async {
      final mockDataSource = MockHomeRemoteDataSource(
        categories: [
          const CategoryModel(id: 'c1', name: 'Fruits', displayOrder: 1),
          const CategoryModel(id: 'c2', name: 'Vegetables', displayOrder: 2),
          const CategoryModel(id: 'c3', name: 'Exotics', displayOrder: 3),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(homeCategoriesProvider.future);

      expect(result.length, equals(3));
      expect(result[0].name, equals('Fruits'));
      expect(result[1].name, equals('Vegetables'));
      expect(result[2].name, equals('Exotics'));
      expect(mockDataSource.callCount, equals(1));
    });

    test('4. homeCategoriesProvider preserves backend ordering', () async {
      final mockDataSource = MockHomeRemoteDataSource(
        categories: [
          const CategoryModel(id: 'c1', name: 'Order 1', displayOrder: 1),
          const CategoryModel(id: 'c2', name: 'Order 2', displayOrder: 2),
          const CategoryModel(id: 'c3', name: 'Order 3', displayOrder: 3),
          const CategoryModel(id: 'c4', name: 'Order 4', displayOrder: 4),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(homeCategoriesProvider.future);

      expect(result.map((c) => c.displayOrder).toList(), equals([1, 2, 3, 4]));
    });

    test('5. Empty category response returns empty list without error', () async {
      final mockDataSource = MockHomeRemoteDataSource(categories: []);

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(homeCategoriesProvider.future);

      expect(result, isEmpty);
    });

    test('6. Category API error propagates as AsyncError without fabricating fake data', () async {
      final mockDataSource = MockHomeRemoteDataSource(shouldThrow: true);

      final container = ProviderContainer(
        overrides: [
          homeRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(homeCategoriesProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
