import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

abstract class OrderRemoteDataSource {
  Future<Map<String, dynamic>> createOrder({
    required String fulfillmentType,
    required String? addressId,
    required String? storeId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  });

  Future<Map<String, dynamic>> getOrderById(String orderId);

  Future<List<dynamic>> getOrders() async => [];
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient _apiClient;

  OrderRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> createOrder({
    required String fulfillmentType,
    required String? addressId,
    required String? storeId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.orders,
      data: {
        'fulfillmentType': fulfillmentType,
        if (addressId != null) 'addressId': addressId,
        if (storeId != null) 'storeId': storeId,
        'paymentMethod': paymentMethod,
        'items': items,
      },
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final response = await _apiClient.get(
      ApiEndpoints.orderById(orderId),
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
  }

  @override
  Future<List<dynamic>> getOrders() async {
    final response = await _apiClient.get(ApiEndpoints.orders);
    if (response is Map<String, dynamic>) {
      final orders = response['orders'] ?? response['data'];
      if (orders is List) {
        return orders;
      }
    } else if (response is List) {
      return response;
    }
    return <dynamic>[];
  }
}

