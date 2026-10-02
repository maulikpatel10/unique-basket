import '../datasources/favorites_remote_data_source.dart';

abstract class FavoritesRepository {
  Future<List<String>> getFavoriteProductIds();
  Future<bool> addFavorite(String productId);
  Future<bool> removeFavorite(String productId);
}

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDataSource _remoteDataSource;

  FavoritesRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<String>> getFavoriteProductIds() {
    return _remoteDataSource.getFavoriteProductIds();
  }

  @override
  Future<bool> addFavorite(String productId) {
    return _remoteDataSource.addFavorite(productId);
  }

  @override
  Future<bool> removeFavorite(String productId) {
    return _remoteDataSource.removeFavorite(productId);
  }
}
