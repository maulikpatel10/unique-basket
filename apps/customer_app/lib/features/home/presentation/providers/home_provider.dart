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

final homeBannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getBanners();
});

/// State for active quantities in cart mapped by productId.
class CartStateNotifier extends StateNotifier<Map<String, int>> {
  CartStateNotifier() : super({});

  void increment(String productId) {
    state = {
      ...state,
      productId: (state[productId] ?? 0) + 1,
    };
  }

  void decrement(String productId) {
    final current = state[productId] ?? 0;
    if (current <= 1) {
      final updated = Map<String, int>.from(state)..remove(productId);
      state = updated;
    } else {
      state = {
        ...state,
        productId: current - 1,
      };
    }
  }

  int getQuantity(String productId) => state[productId] ?? 0;

  int get totalItemCount => state.values.fold(0, (sum, q) => sum + q);

  double calculateTotal(List<ProductModel> products) {
    double total = 0.0;
    for (final entry in state.entries) {
      final product = products.cast<ProductModel?>().firstWhere(
            (p) => p?.id == entry.key,
            orElse: () => null,
          );
      if (product != null) {
        total += product.price * entry.value;
      }
    }
    return total;
  }
}

final cartNotifierProvider =
    StateNotifierProvider<CartStateNotifier, Map<String, int>>((ref) {
  return CartStateNotifier();
});

/// State for wishlist/favorite product IDs.
class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({});

  void toggleFavorite(String productId) {
    if (state.contains(productId)) {
      state = Set.from(state)..remove(productId);
    } else {
      state = Set.from(state)..add(productId);
    }
  }

  bool isFavorite(String productId) => state.contains(productId);
}

final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});
