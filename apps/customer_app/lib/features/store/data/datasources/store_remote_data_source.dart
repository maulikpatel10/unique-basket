import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/store_model.dart';

abstract class StoreRemoteDataSource {
  Future<List<StoreModel>> getNearbyStores({
    required double latitude,
    required double longitude,
    String fulfillment = 'DELIVERY',
  });
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  final ApiClient _apiClient;

  StoreRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<StoreModel>> getNearbyStores({
    required double latitude,
    required double longitude,
    String fulfillment = 'DELIVERY',
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.nearbyStores,
      queryParameters: {
        'lat': latitude,
        'lng': longitude,
        'fulfillment': fulfillment,
      },
    );

    if (response is List) {
      return response
          .map((item) => StoreModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .map((item) => StoreModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}
