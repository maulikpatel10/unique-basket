export '../../../cart/presentation/providers/cart_provider.dart';
export '../../../favorites/presentation/providers/favorites_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../../data/datasources/home_remote_data_source.dart';
import '../../data/models/banner_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/home_repository.dart';

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeRemoteDataSourceImpl(apiClient);
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final remoteDataSource = ref.watch(homeRemoteDataSourceProvider);
  return HomeRepositoryImpl(remoteDataSource);
});

final homeCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getCategories();
});

/// Provider for products specific to a given store ID with inventory.
final storeProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, storeId) async {
  if (storeId.isEmpty) return [];
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getStoreProducts(storeId);
});

/// Home products provider that dynamically depends on the customer's resolved serving store.
final homeProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final servingStore = await ref.watch(servingStoreProvider.future);
  if (servingStore == null || servingStore.id.isEmpty) {
    return [];
  }
  return ref.watch(storeProductsProvider(servingStore.id).future);
});

/// Category products provider that dynamically queries the customer's resolved serving store
/// filtered by category ID.
final categoryProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, categoryId) async {
  final servingStore = await ref.watch(servingStoreProvider.future);
  if (servingStore == null || servingStore.id.isEmpty) {
    return [];
  }
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getStoreProducts(
    servingStore.id,
    categoryId: categoryId.isNotEmpty ? categoryId : null,
  );
});

final homeBannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getBanners();
});


