import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/favorites_remote_data_source.dart';
import '../../data/repositories/favorites_repository.dart';

final favoritesRemoteDataSourceProvider = Provider<FavoritesRemoteDataSource>((ref) {
  ApiClient? apiClient;
  try {
    apiClient = ref.watch(apiClientProvider);
  } catch (_) {}
  return FavoritesRemoteDataSourceImpl(
    apiClient ?? ApiClient(secureStorage: SecureStorageService()),
  );
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final remoteDataSource = ref.watch(favoritesRemoteDataSourceProvider);
  return FavoritesRepositoryImpl(remoteDataSource);
});

/// State for wishlist/favorite product IDs with authoritative backend persistence and local cache.
class FavoritesNotifier extends StateNotifier<Set<String>> {
  final FavoritesRepository? _favoritesRepository;
  final LocalStorageService? _storage;
  final SecureStorageService? _secureStorage;

  FavoritesNotifier({
    FavoritesRepository? favoritesRepository,
    LocalStorageService? localStorage,
    SecureStorageService? secureStorage,
  })  : _favoritesRepository = favoritesRepository,
        _storage = localStorage,
        _secureStorage = secureStorage,
        super({}) {
    _init();
  }

  void _init() {
    _loadFromLocalCache();
    loadFavorites();
  }

  /// Loads saved favorites from user-scoped local cache for instant display.
  void _loadFromLocalCache() {
    if (_storage == null) return;
    try {
      final savedList = _storage!.getStringList(AppConstants.keyUserFavorites);
      if (savedList != null && savedList.isNotEmpty) {
        state = Set<String>.from(savedList);
        if (kDebugMode) {
          debugPrint('[UB-PERSISTENCE] FAVORITES LOCAL CACHE LOADED: count=${savedList.length}');
        }
      }
    } catch (_) {}
  }

  /// Fetches authoritative favorites list from backend server if authenticated.
  Future<void> loadFavorites() async {
    if (_favoritesRepository == null) return;
    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] FAVORITES LOAD START');
    }
    try {
      final token = await _secureStorage?.getAccessToken();
      final hasToken = token != null && token.trim().isNotEmpty;
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] FAVORITES AUTH TOKEN EXISTS: $hasToken');
      }
      if (!hasToken) return;

      final remoteIds = await _favoritesRepository!.getFavoriteProductIds();
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] FAVORITES SERVER ITEMS: count=${remoteIds.length}');
      }
      state = Set<String>.from(remoteIds);
      _saveFavorites();
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] FAVORITES PROVIDER HYDRATED: count=${state.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] FAVORITES LOAD ERROR (retaining local state): $e');
      }
      // Retain local cache if network request fails
    }
  }


  /// Persists the active favorites set to user-scoped storage.
  void _saveFavorites() {
    if (_storage == null) return;
    try {
      if (state.isEmpty) {
        _storage!.remove(AppConstants.keyUserFavorites);
      } else {
        _storage!.setStringList(AppConstants.keyUserFavorites, state.toList());
      }
    } catch (_) {}
  }

  void toggleFavorite(String productId) {
    if (state.contains(productId)) {
      removeFavorite(productId);
    } else {
      addFavorite(productId);
    }
  }

  void addFavorite(String productId) {
    if (!state.contains(productId)) {
      state = Set.from(state)..add(productId);
      _saveFavorites();
      _syncAddFavorite(productId);
    }
  }

  void removeFavorite(String productId) {
    if (state.contains(productId)) {
      state = Set.from(state)..remove(productId);
      _saveFavorites();
      _syncRemoveFavorite(productId);
    }
  }

  void setFavorites(Iterable<String> productIds) {
    state = Set<String>.from(productIds);
    _saveFavorites();
  }

  bool isFavorite(String productId) => state.contains(productId);

  void clearFavorites() {
    state = {};
    if (_storage != null) {
      _storage!.remove(AppConstants.keyUserFavorites);
    }
  }

  // --- Backend Synchronization Helpers ---

  Future<void> _syncAddFavorite(String productId) async {
    if (_favoritesRepository == null) return;
    try {
      final token = await _secureStorage?.getAccessToken();
      if (token == null || token.trim().isEmpty) return;

      await _favoritesRepository!.addFavorite(productId);
    } catch (_) {}
  }

  Future<void> _syncRemoveFavorite(String productId) async {
    if (_favoritesRepository == null) return;
    try {
      final token = await _secureStorage?.getAccessToken();
      if (token == null || token.trim().isEmpty) return;

      await _favoritesRepository!.removeFavorite(productId);
    } catch (_) {}
  }
}

final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  FavoritesRepository? favoritesRepository;
  try {
    favoritesRepository = ref.watch(favoritesRepositoryProvider);
  } catch (_) {}

  LocalStorageService? storage;
  try {
    storage = ref.watch(localStorageProvider);
  } catch (_) {}

  SecureStorageService? secureStorage;
  try {
    secureStorage = ref.watch(secureStorageProvider);
  } catch (_) {}

  return FavoritesNotifier(
    favoritesRepository: favoritesRepository,
    localStorage: storage,
    secureStorage: secureStorage,
  );
});
