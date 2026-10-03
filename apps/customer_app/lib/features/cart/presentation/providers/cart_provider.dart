import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../home/data/models/product_model.dart';
import '../../data/datasources/cart_remote_data_source.dart';
import '../../data/models/cart_summary_model.dart';
import '../../data/models/delivery_settings_model.dart';
import '../../data/repositories/cart_repository.dart';

export '../../data/models/cart_item_model.dart';
export '../../data/models/cart_summary_model.dart';
export '../../data/models/delivery_settings_model.dart';

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  ApiClient? apiClient;
  try {
    apiClient = ref.watch(apiClientProvider);
  } catch (_) {}
  return CartRemoteDataSourceImpl(
    apiClient ?? ApiClient(secureStorage: SecureStorageService()),
  );
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final remoteDataSource = ref.watch(cartRemoteDataSourceProvider);
  return CartRepositoryImpl(remoteDataSource);
});

final deliverySettingsProvider = FutureProvider<DeliverySettingsModel>((ref) async {
  final cartRepo = ref.watch(cartRepositoryProvider);
  return cartRepo.getDeliverySettings();
});

final cartSummaryProvider = FutureProvider<CartSummaryModel>((ref) async {
  final cart = ref.watch(cartNotifierProvider);
  if (cart.isEmpty) {
    return const CartSummaryModel();
  }
  final cartRepo = ref.watch(cartRepositoryProvider);
  return cartRepo.getCartSummary();
});

/// Sync status enum for Cart state lifecycle
enum CartSyncStatus {
  idle,
  initialLoading,
  refreshing,
  error,
}

/// Provider exposing whether Cart is currently performing an initial load or background refresh.
final cartSyncStatusProvider = StateProvider<CartSyncStatus>((ref) => CartSyncStatus.idle);

/// P1-06: user-facing message set when a cart change could not be saved to the server.
/// The cart is then reloaded from the server so local and server state do not diverge.
final cartSyncErrorProvider = StateProvider<String?>((ref) => null);

const String cartSyncFailedMessage = "Couldn't update your cart. Showing your latest saved cart.";

/// State for active quantities in cart mapped by productId.
///
/// Quantities are decimals in the product's unit (D-012): e.g. 1.25 (KG), 250 (GRAM), 2 (PIECE).
class CartStateNotifier extends StateNotifier<Map<String, double>> {
  final Ref? _ref;
  final CartRepository? _cartRepository;
  final LocalStorageService? _localStorage;
  final SecureStorageService? _secureStorage;

  final Map<String, String> _productIdToCartItemId = {};

  CartStateNotifier({
    Ref? ref,
    CartRepository? cartRepository,
    LocalStorageService? localStorage,
    SecureStorageService? secureStorage,
  })  : _ref = ref,
        _cartRepository = cartRepository,
        _localStorage = localStorage,
        _secureStorage = secureStorage,
        super(_initialState(localStorage)) {
    _init();
  }

  /// Synchronously extract initial cached cart state from local storage.
  static Map<String, double> _initialState(LocalStorageService? localStorage) {
    if (localStorage == null) return {};
    try {
      final cachedJson = localStorage.getJson(AppConstants.keyUserCart);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, double> loaded = {};
        for (final entry in cachedJson.entries) {
          final val = entry.value;
          final qty = val is num ? val.toDouble() : double.tryParse(val.toString()) ?? 0;
          if (qty > 0) {
            loaded[entry.key] = qty;
          }
        }
        return loaded;
      }
    } catch (_) {}
    return {};
  }

  void _init() {
    _loadFromLocalCache();
    loadCart();
  }

  /// Loads cart from user-scoped local storage for instant offline/restart display.
  void _loadFromLocalCache() {
    if (_localStorage == null) return;
    try {
      final cachedJson = _localStorage!.getJson(AppConstants.keyUserCart);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, double> loaded = {};
        for (final entry in cachedJson.entries) {
          final val = entry.value;
          final qty = val is num ? val.toDouble() : double.tryParse(val.toString()) ?? 0;
          if (qty > 0) {
            loaded[entry.key] = qty;
          }
        }
        if (loaded.isNotEmpty) {
          state = loaded;
          if (kDebugMode) {
            debugPrint('[UB-PERSISTENCE] CART LOCAL CACHE LOADED: count=${loaded.length}');
          }
        }
      }
    } catch (_) {
      // Gracefully ignore corrupt cache
    }
  }

  /// Persists current cart state to user-scoped local storage.
  void _saveToLocalCache() {
    if (_localStorage == null) return;
    try {
      if (state.isEmpty) {
        _localStorage!.remove(AppConstants.keyUserCart);
      } else {
        _localStorage!.setJson(AppConstants.keyUserCart, Map<String, dynamic>.from(state));
      }
    } catch (_) {}
  }

  /// Fetches the latest cart state from the backend server if authenticated.
  Future<void> loadCart() async {
    if (!mounted || _cartRepository == null) return;
    try {
      final token = await _secureStorage?.getAccessToken();
      if (!mounted) return;
      final hasToken = token != null && token.trim().isNotEmpty;
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] AUTH TOKEN EXISTS: $hasToken');
      }
      if (!hasToken) {
        if (_ref != null) {
          _ref!.read(cartSyncStatusProvider.notifier).state = CartSyncStatus.idle;
        }
        return;
      }

      final isInitial = state.isEmpty;
      if (_ref != null) {
        _ref!.read(cartSyncStatusProvider.notifier).state =
            isInitial ? CartSyncStatus.initialLoading : CartSyncStatus.refreshing;
      }
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] CART LOAD START');
      }

      final items = await _cartRepository!.getCart();
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] CART SERVER ITEMS: count=${items.length}');
      }
      final Map<String, double> remoteCart = {};
      _productIdToCartItemId.clear();

      for (final item in items) {
        if (item.quantity > 0) {
          remoteCart[item.productId] = item.quantity;
          if (item.id.isNotEmpty) {
            _productIdToCartItemId[item.productId] = item.id;
          }
        }
      }

      state = remoteCart;
      _saveToLocalCache();
      if (_ref != null && mounted) {
        _ref!.read(cartSyncStatusProvider.notifier).state = CartSyncStatus.idle;
      }
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] CART PROVIDER HYDRATED: count=${state.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] CART LOAD ERROR (retaining local state): $e');
      }
      if (_ref != null && mounted) {
        _ref!.read(cartSyncStatusProvider.notifier).state = CartSyncStatus.error;
      }
      // Retain local cache if network request fails
    }
  }

  /// Adds one [rule] step (or the rule minimum when the product is not in the cart).
  /// No-op when the configured maximum is reached. Without a rule, the
  /// product's unconfigured behaviour applies (start at 1, step 1).
  void increment(String productId, {QuantityRule? rule}) {
    final current = state[productId] ?? 0;
    final newQty = (rule ?? const QuantityRule.unconfigured('')).next(current);
    if (newQty == null) return;
    state = {
      ...state,
      productId: newQty,
    };
    _saveToLocalCache();
    _syncAddItem(productId, newQty);
  }

  /// Removes one [rule] step; removes the line when it would drop below the minimum.
  void decrement(String productId, {QuantityRule? rule}) {
    final current = state[productId] ?? 0;
    final newQty = (rule ?? const QuantityRule.unconfigured('')).previous(current);
    if (newQty <= 0) {
      removeItem(productId);
    } else {
      state = {
        ...state,
        productId: newQty,
      };
      _saveToLocalCache();
      _syncUpdateItem(productId, newQty);
    }
  }

  void removeItem(String productId) {
    if (state.containsKey(productId)) {
      final updated = Map<String, double>.from(state)..remove(productId);
      state = updated;
      _saveToLocalCache();
      _syncRemoveItem(productId);
    }
  }

  void setCart(Map<String, num> cart) {
    final Map<String, double> clean = {};
    for (final entry in cart.entries) {
      if (entry.value > 0) {
        clean[entry.key] = entry.value.toDouble();
      }
    }
    state = clean;
    _saveToLocalCache();
  }

  void setItemQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
    } else {
      state = {
        ...state,
        productId: quantity,
      };
      _saveToLocalCache();
      _syncUpdateItem(productId, quantity);
    }
  }

  void clearCart() {
    state = {};
    _productIdToCartItemId.clear();
    if (_localStorage != null) {
      _localStorage!.remove(AppConstants.keyUserCart);
    }
  }

  double getQuantity(String productId) => state[productId] ?? 0;

  /// Number of product lines in the cart (D-012: the badge counts lines, not
  /// total quantity — 2 kg potatoes + 5 apples = 2 items).
  int get totalItemCount => state.length;

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

  // --- Backend Synchronization Helpers ---

  Future<void> _syncAddItem(String productId, double quantity) async {
    if (_cartRepository == null) return;
    try {
      final token = await _secureStorage?.getAccessToken();
      if (token == null || token.trim().isEmpty) return;

      final res = await _cartRepository!.addItem(
        productId: productId,
        quantity: quantity,
      );
      if (res.containsKey('id') && res['id'] is String) {
        _productIdToCartItemId[productId] = res['id'] as String;
      }
    } catch (e) {
      await _onSyncFailed(e);
    }
  }

  Future<void> _syncUpdateItem(String productId, double quantity) async {
    if (_cartRepository == null) return;
    try {
      final token = await _secureStorage?.getAccessToken();
      if (token == null || token.trim().isEmpty) return;

      final cartItemId = _productIdToCartItemId[productId];
      if (cartItemId != null && cartItemId.isNotEmpty) {
        await _cartRepository!.updateItem(
          cartItemId: cartItemId,
          quantity: quantity,
        );
      } else {
        await _syncAddItem(productId, quantity);
      }
    } catch (e) {
      await _onSyncFailed(e);
    }
  }

  Future<void> _syncRemoveItem(String productId) async {
    if (_cartRepository == null) return;
    try {
      final token = await _secureStorage?.getAccessToken();
      if (token == null || token.trim().isEmpty) return;

      final cartItemId = _productIdToCartItemId.remove(productId);
      if (cartItemId != null && cartItemId.isNotEmpty) {
        await _cartRepository!.removeItem(cartItemId);
      }
    } catch (e) {
      await _onSyncFailed(e);
    }
  }

  /// P1-06: a cart change failed on the server. Surface it and reconcile with the
  /// server cart (rolls back the optimistic local change when the server is reachable).
  Future<void> _onSyncFailed(Object error) async {
    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] CART SYNC FAILED: $error');
    }
    if (!mounted) return;
    if (_ref != null) {
      _ref!.read(cartSyncErrorProvider.notifier).state = cartSyncFailedMessage;
    }
    await loadCart();
  }
}

final cartNotifierProvider =
    StateNotifierProvider<CartStateNotifier, Map<String, double>>((ref) {
  CartRepository? cartRepository;
  try {
    cartRepository = ref.watch(cartRepositoryProvider);
  } catch (_) {}

  LocalStorageService? localStorage;
  try {
    localStorage = ref.watch(localStorageProvider);
  } catch (_) {}

  SecureStorageService? secureStorage;
  try {
    secureStorage = ref.watch(secureStorageProvider);
  } catch (_) {}

  return CartStateNotifier(
    ref: ref,
    cartRepository: cartRepository,
    localStorage: localStorage,
    secureStorage: secureStorage,
  );
});
