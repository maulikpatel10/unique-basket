import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class FavoritesRemoteDataSource {
  Future<List<String>> getFavoriteProductIds();
  Future<bool> addFavorite(String productId);
  Future<bool> removeFavorite(String productId);
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  final ApiClient _apiClient;

  FavoritesRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<String>> getFavoriteProductIds() async {
    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] FAVORITES API REQUEST -> ${ApiEndpoints.favorites}');
    }
    final response = await _apiClient.get(ApiEndpoints.favorites);

    dynamic payload = response;
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      payload = response['data'];
    }

    if (payload is Map<String, dynamic>) {
      final productIds = payload['productIds'];
      if (productIds is List) {
        final result = productIds.map((e) => e.toString()).toList();
        if (kDebugMode) {
          debugPrint('[UB-PERSISTENCE] FAVORITES API RESPONSE productIds count: ${result.length}');
        }
        return result;
      }
      final favorites = payload['favorites'];
      if (favorites is List) {
        final result = favorites
            .map((f) => f is Map<String, dynamic> ? (f['productId']?.toString() ?? '') : f.toString())
            .where((id) => id.isNotEmpty)
            .toList();
        if (kDebugMode) {
          debugPrint('[UB-PERSISTENCE] FAVORITES API RESPONSE favorites list count: ${result.length}');
        }
        return result;
      }
    } else if (payload is List) {
      final result = payload
          .map((f) => f is Map<String, dynamic> ? (f['productId']?.toString() ?? '') : f.toString())
          .where((id) => id.isNotEmpty)
          .toList();
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] FAVORITES API RESPONSE raw list count: ${result.length}');
      }
      return result;
    }
    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] FAVORITES API RESPONSE empty/unexpected payload');
    }
    return <String>[];
  }

  @override
  Future<bool> addFavorite(String productId) async {
    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] FAVORITE ADD API REQUEST: productId=$productId');
    }
    final response = await _apiClient.post(
      ApiEndpoints.favoriteProduct(productId),
    );

    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] FAVORITE ADD API SUCCESS: productId=$productId');
    }

    if (response is Map<String, dynamic>) {
      return response['success'] == true;
    }
    return true;
  }

  @override
  Future<bool> removeFavorite(String productId) async {
    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] FAVORITE REMOVE API REQUEST: productId=$productId');
    }
    final response = await _apiClient.delete(
      ApiEndpoints.favoriteProduct(productId),
    );

    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] FAVORITE REMOVE API SUCCESS: productId=$productId');
    }

    if (response is Map<String, dynamic>) {
      return response['success'] == true;
    }
    return true;
  }
}

