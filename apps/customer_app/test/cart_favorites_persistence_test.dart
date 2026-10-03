import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/core/network/api_client.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:customer_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:customer_app/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:customer_app/features/cart/data/repositories/cart_repository.dart';
import 'package:customer_app/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:customer_app/features/favorites/data/repositories/favorites_repository.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';

class FakeApiClient extends ApiClient {
  dynamic getResponse;
  dynamic postResponse;
  dynamic putResponse;
  dynamic deleteResponse;

  FakeApiClient() : super(secureStorage: SecureStorageService());

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    return getResponse;
  }

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return postResponse ?? {'success': true};
  }

  @override
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return putResponse ?? {'success': true};
  }

  @override
  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return deleteResponse ?? {'success': true};
  }
}

class MockCartRepository implements CartRepository {
  List<CartItemModel> items = [];
  Map<String, dynamic>? lastAddPayload;
  Map<String, dynamic>? lastUpdatePayload;
  String? lastRemovedId;

  @override
  Future<List<CartItemModel>> getCart() async {
    return List.from(items);
  }

  @override
  Future<CartSummaryModel> getCartSummary() async {
    double subtotal = 0.0;
    for (final i in items) {
      subtotal += i.totalPrice;
    }
    final fee = subtotal > 0 ? (subtotal >= 200.0 ? 0.0 : 30.0) : 0.0;
    return CartSummaryModel(
      items: List.from(items),
      subtotal: subtotal,
      deliveryFee: fee,
      total: subtotal + fee,
      freeDeliveryThreshold: 200.0,
    );
  }

  @override
  Future<DeliverySettingsModel> getDeliverySettings() async {
    return const DeliverySettingsModel();
  }

  @override
  Future<Map<String, dynamic>> addItem({required String productId, required int quantity}) async {
    lastAddPayload = {'productId': productId, 'quantity': quantity};
    final existingIndex = items.indexWhere((i) => i.productId == productId);
    final itemId = existingIndex >= 0 ? items[existingIndex].id : 'cart_item_$productId';
    final newItem = CartItemModel(
      id: itemId,
      productId: productId,
      price: 50.0,
      quantity: quantity,
      totalPrice: 50.0 * quantity,
    );
    if (existingIndex >= 0) {
      items[existingIndex] = newItem;
    } else {
      items.add(newItem);
    }
    return {'id': itemId, 'productId': productId, 'quantity': quantity};
  }

  @override
  Future<Map<String, dynamic>> updateItem({required String cartItemId, required int quantity}) async {
    lastUpdatePayload = {'cartItemId': cartItemId, 'quantity': quantity};
    final index = items.indexWhere((i) => i.id == cartItemId);
    if (index >= 0) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(quantity: quantity, totalPrice: items[index].price * quantity);
      }
    }
    return {'id': cartItemId, 'quantity': quantity};
  }

  @override
  Future<bool> removeItem(String cartItemId) async {
    lastRemovedId = cartItemId;
    items.removeWhere((i) => i.id == cartItemId);
    return true;
  }
}

class MockFavoritesRepository implements FavoritesRepository {
  List<String> favoriteIds = [];
  String? lastAddedId;
  String? lastRemovedId;

  @override
  Future<List<String>> getFavoriteProductIds() async {
    return List.from(favoriteIds);
  }

  @override
  Future<bool> addFavorite(String productId) async {
    lastAddedId = productId;
    if (!favoriteIds.contains(productId)) {
      favoriteIds.add(productId);
    }
    return true;
  }

  @override
  Future<bool> removeFavorite(String productId) async {
    lastRemovedId = productId;
    favoriteIds.remove(productId);
    return true;
  }
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    return {'success': true, 'token': 'mock_token'};
  }

  @override
  Future<String?> refreshToken(String refreshToken) async => 'mock_token';
}

void main() {
  setUpAll(() {
    AppConfig.initialize(
      appName: 'Unique Basket',
      environment: Environment.development,
    );
  });

  group('Cart & Favourites Persistence & Restart Tests', () {
    late LocalStorageService localStorage;
    late SecureStorageService secureStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      localStorage = LocalStorageService(prefs);
      secureStorage = SecureStorageService();
      await secureStorage.clearTokens();
    });

    test('1. Favourites persist across notifier recreation / app restart', () async {
      final mockFavRepo = MockFavoritesRepository();
      final container1 = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          favoritesRepositoryProvider.overrideWithValue(mockFavRepo),
        ],
      );

      // User adds Avocado and Kale to Favorites
      final favNotifier1 = container1.read(favoritesNotifierProvider.notifier);
      favNotifier1.toggleFavorite('p_avocado');
      favNotifier1.toggleFavorite('p_kale');

      expect(container1.read(favoritesNotifierProvider), equals({'p_avocado', 'p_kale'}));
      expect(container1.read(favoritesNotifierProvider.notifier).isFavorite('p_avocado'), isTrue);
      expect(container1.read(favoritesNotifierProvider.notifier).isFavorite('p_kale'), isTrue);
      expect(container1.read(favoritesNotifierProvider.notifier).isFavorite('p_bread'), isFalse);

      container1.dispose();

      // Simulate App Restart (new container reading the same persistent storage)
      final container2 = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          favoritesRepositoryProvider.overrideWithValue(mockFavRepo),
        ],
      );

      final favState2 = container2.read(favoritesNotifierProvider);
      expect(favState2, equals({'p_avocado', 'p_kale'}));
      expect(container2.read(favoritesNotifierProvider.notifier).isFavorite('p_avocado'), isTrue);
      expect(container2.read(favoritesNotifierProvider.notifier).isFavorite('p_kale'), isTrue);
      expect(container2.read(favoritesNotifierProvider.notifier).isFavorite('p_bread'), isFalse);

      container2.dispose();
    });

    test('2. Cart local persistence survives provider recreation / app restart', () async {
      final mockCartRepo = MockCartRepository();

      final container1 = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
        ],
      );

      final cartNotifier1 = container1.read(cartNotifierProvider.notifier);
      cartNotifier1.increment('p_avocado');
      cartNotifier1.increment('p_avocado');
      cartNotifier1.increment('p_bread');

      expect(container1.read(cartNotifierProvider), equals({'p_avocado': 2, 'p_bread': 1}));
      expect(cartNotifier1.totalItemCount, equals(3));
      expect(cartNotifier1.getQuantity('p_avocado'), equals(2));
      expect(cartNotifier1.getQuantity('p_bread'), equals(1));

      container1.dispose();

      // Simulate App Restart with fresh container
      final container2 = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
        ],
      );

      final cartState2 = container2.read(cartNotifierProvider);
      final cartNotifier2 = container2.read(cartNotifierProvider.notifier);

      expect(cartState2, equals({'p_avocado': 2, 'p_bread': 1}));
      expect(cartNotifier2.totalItemCount, equals(3));
      expect(cartNotifier2.getQuantity('p_avocado'), equals(2));
      expect(cartNotifier2.getQuantity('p_bread'), equals(1));

      container2.dispose();
    });

    test('3. Cart mutations (increment, decrement, remove, clear) persist correctly', () async {
      final mockCartRepo = MockCartRepository();

      final container1 = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
        ],
      );

      final cartNotifier1 = container1.read(cartNotifierProvider.notifier);
      cartNotifier1.increment('p_kale');
      cartNotifier1.increment('p_kale');
      cartNotifier1.decrement('p_kale'); // Now 1
      cartNotifier1.increment('p_tomato'); // Now 1
      cartNotifier1.removeItem('p_tomato'); // Removed

      expect(container1.read(cartNotifierProvider), equals({'p_kale': 1}));

      container1.dispose();

      // Restart app
      final container2 = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
        ],
      );

      expect(container2.read(cartNotifierProvider), equals({'p_kale': 1}));

      // Clear cart
      container2.read(cartNotifierProvider.notifier).clearCart();
      expect(container2.read(cartNotifierProvider), isEmpty);

      container2.dispose();

      // Restart app after clearing cart
      final container3 = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
        ],
      );

      expect(container3.read(cartNotifierProvider), isEmpty);
      container3.dispose();
    });

    test('4. Authenticated backend cart sync restores on app startup', () async {
      await secureStorage.saveTokens(
        accessToken: 'valid_mock_access_token',
        refreshToken: 'valid_mock_refresh_token',
      );

      final mockCartRepo = MockCartRepository();
      mockCartRepo.items = [
        const CartItemModel(
          id: 'item_101',
          productId: 'p_avocado',
          price: 180.0,
          quantity: 3,
          totalPrice: 540.0,
        ),
        const CartItemModel(
          id: 'item_102',
          productId: 'p_kale',
          price: 60.0,
          quantity: 2,
          totalPrice: 120.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
        ],
      );

      // Trigger cart load
      await container.read(cartNotifierProvider.notifier).loadCart();

      final cartState = container.read(cartNotifierProvider);
      expect(cartState, equals({'p_avocado': 3, 'p_kale': 2}));
      expect(container.read(cartNotifierProvider.notifier).totalItemCount, equals(5));

      container.dispose();
    });

    test('5. Reinstall Simulation: Cart & Favourites restore from backend when local storage is empty', () async {
      // Setup backend state for User A
      final mockCartRepo = MockCartRepository();
      mockCartRepo.items = [
        const CartItemModel(
          id: 'item_apple',
          productId: 'p_apple',
          price: 120.0,
          quantity: 2,
          totalPrice: 240.0,
        ),
        const CartItemModel(
          id: 'item_banana',
          productId: 'p_banana',
          price: 60.0,
          quantity: 1,
          totalPrice: 60.0,
        ),
      ];

      final mockFavRepo = MockFavoritesRepository();
      mockFavRepo.favoriteIds = ['p_apple', 'p_tomato'];

      // App is completely fresh/reinstalled (EMPTY SharedPreferences & Empty local storage)
      SharedPreferences.setMockInitialValues({});
      final freshPrefs = await SharedPreferences.getInstance();
      final freshLocalStorage = LocalStorageService(freshPrefs);
      final freshSecureStorage = SecureStorageService();

      // User logs in and receives tokens
      await freshSecureStorage.saveTokens(
        accessToken: 'user_a_token',
        refreshToken: 'user_a_refresh_token',
      );

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(freshLocalStorage),
          secureStorageProvider.overrideWithValue(freshSecureStorage),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          favoritesRepositoryProvider.overrideWithValue(mockFavRepo),
        ],
      );

      // Startup restoration runs
      await container.read(cartNotifierProvider.notifier).loadCart();
      await container.read(favoritesNotifierProvider.notifier).loadFavorites();

      // Verify Cart and Favourites are restored directly from backend
      expect(container.read(cartNotifierProvider), equals({'p_apple': 2, 'p_banana': 1}));
      expect(container.read(cartNotifierProvider.notifier).totalItemCount, equals(3));
      expect(container.read(favoritesNotifierProvider), equals({'p_apple', 'p_tomato'}));
      expect(container.read(favoritesNotifierProvider.notifier).isFavorite('p_apple'), isTrue);
      expect(container.read(favoritesNotifierProvider.notifier).isFavorite('p_tomato'), isTrue);

      container.dispose();
    });

    test('6. User account isolation: Logout clears User A state, User B does not see User A data', () async {
      final mockCartRepo = MockCartRepository();
      final mockFavRepo = MockFavoritesRepository();

      // --- USER A SESSION ---
      final containerUserA = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          favoritesRepositoryProvider.overrideWithValue(mockFavRepo),
        ],
      );

      containerUserA.read(cartNotifierProvider.notifier).increment('p_avocado');
      containerUserA.read(cartNotifierProvider.notifier).increment('p_banana');
      containerUserA.read(favoritesNotifierProvider.notifier).toggleFavorite('p_tomato');

      expect(containerUserA.read(cartNotifierProvider), equals({'p_avocado': 1, 'p_banana': 1}));
      expect(containerUserA.read(favoritesNotifierProvider), equals({'p_tomato'}));

      // User A logs out
      await containerUserA.read(authNotifierProvider.notifier).logout();

      expect(containerUserA.read(cartNotifierProvider), isEmpty);
      expect(containerUserA.read(favoritesNotifierProvider), isEmpty);

      containerUserA.dispose();

      // --- USER B SESSION (App Restart / New Session) ---
      final containerUserB = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          favoritesRepositoryProvider.overrideWithValue(mockFavRepo),
        ],
      );

      // User B must start with clean state
      expect(containerUserB.read(cartNotifierProvider), isEmpty);
      expect(containerUserB.read(favoritesNotifierProvider), isEmpty);

      // User B adds mango to cart and pineapple to favorites
      containerUserB.read(cartNotifierProvider.notifier).increment('p_mango');
      containerUserB.read(favoritesNotifierProvider.notifier).toggleFavorite('p_pineapple');
      expect(containerUserB.read(cartNotifierProvider), equals({'p_mango': 1}));
      expect(containerUserB.read(favoritesNotifierProvider), equals({'p_pineapple'}));

      containerUserB.dispose();

      // Restart app for User B
      final containerUserBRestart = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          favoritesRepositoryProvider.overrideWithValue(mockFavRepo),
        ],
      );

      expect(containerUserBRestart.read(cartNotifierProvider), equals({'p_mango': 1}));
      expect(containerUserBRestart.read(favoritesNotifierProvider), equals({'p_pineapple'}));

      containerUserBRestart.dispose();
    });

    test('7. CartRemoteDataSourceImpl correctly parses both unwrapped and wrapped backend payloads', () async {
      final fakeApiClient = FakeApiClient();
      final dataSource = CartRemoteDataSourceImpl(fakeApiClient);

      // 7A: Unwrapped backend data shape (ApiClient unpacked response['data'])
      fakeApiClient.getResponse = {
        'items': [
          {
            'id': 'c_item_1',
            'productId': 'p_avocado',
            'productName': 'Fresh Avocado',
            'price': 150.0,
            'quantity': 2,
            'totalPrice': 300.0,
          }
        ],
        'subtotal': 300.0,
      };

      final items1 = await dataSource.getCart();
      expect(items1.length, equals(1));
      expect(items1.first.productId, equals('p_avocado'));
      expect(items1.first.quantity, equals(2));

      // 7B: Wrapped backend data shape ({ 'data': { 'items': [...] } })
      fakeApiClient.getResponse = {
        'data': {
          'items': [
            {
              'id': 'c_item_2',
              'productId': 'p_kale',
              'productName': 'Organic Kale',
              'price': 45.0,
              'quantity': 3,
              'totalPrice': 135.0,
            }
          ],
          'subtotal': 135.0,
        }
      };

      final items2 = await dataSource.getCart();
      expect(items2.length, equals(1));
      expect(items2.first.productId, equals('p_kale'));
      expect(items2.first.quantity, equals(3));
    });

    test('8. FavoritesRemoteDataSourceImpl correctly parses both unwrapped and wrapped backend payloads', () async {
      final fakeApiClient = FakeApiClient();
      final dataSource = FavoritesRemoteDataSourceImpl(fakeApiClient);

      // 8A: Unwrapped backend data shape
      fakeApiClient.getResponse = {
        'productIds': ['p_apple', 'p_banana'],
        'favorites': [
          {'productId': 'p_apple'},
          {'productId': 'p_banana'},
        ],
      };

      final ids1 = await dataSource.getFavoriteProductIds();
      expect(ids1, equals(['p_apple', 'p_banana']));

      // 8B: Wrapped backend data shape
      fakeApiClient.getResponse = {
        'data': {
          'productIds': ['p_mango', 'p_orange'],
          'favorites': [],
        }
      };

      final ids2 = await dataSource.getFavoriteProductIds();
      expect(ids2, equals(['p_mango', 'p_orange']));
    });

    test('9. Full Startup Hydration: Empty local cache + populated remote datasource -> providers hydrated', () async {
      await secureStorage.saveTokens(
        accessToken: 'valid_startup_token',
        refreshToken: 'valid_startup_refresh_token',
      );

      final fakeApiClient = FakeApiClient();
      fakeApiClient.getResponse = {
        'items': [
          {
            'id': 'c_item_apple',
            'productId': 'p_apple',
            'price': 99.0,
            'quantity': 4,
            'totalPrice': 396.0,
          }
        ],
        'productIds': ['p_apple', 'p_grape'],
      };

      final cartDataSource = CartRemoteDataSourceImpl(fakeApiClient);
      final cartRepo = CartRepositoryImpl(cartDataSource);
      final favDataSource = FavoritesRemoteDataSourceImpl(fakeApiClient);
      final favRepo = FavoritesRepositoryImpl(favDataSource);

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
          secureStorageProvider.overrideWithValue(secureStorage),
          cartRepositoryProvider.overrideWithValue(cartRepo),
          favoritesRepositoryProvider.overrideWithValue(favRepo),
        ],
      );

      // Trigger loads
      await container.read(cartNotifierProvider.notifier).loadCart();
      await container.read(favoritesNotifierProvider.notifier).loadFavorites();

      expect(container.read(cartNotifierProvider), equals({'p_apple': 4}));
      expect(container.read(favoritesNotifierProvider), equals({'p_apple', 'p_grape'}));

      container.dispose();
    });
  });
}

