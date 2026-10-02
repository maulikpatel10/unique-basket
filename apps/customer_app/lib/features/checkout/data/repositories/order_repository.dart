import '../datasources/order_remote_data_source.dart';

abstract class OrderRepository {
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

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>> createOrder({
    required String fulfillmentType,
    required String? addressId,
    required String? storeId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) {
    return _remoteDataSource.createOrder(
      fulfillmentType: fulfillmentType,
      addressId: addressId,
      storeId: storeId,
      paymentMethod: paymentMethod,
      items: items,
    );
  }

  @override
  Future<Map<String, dynamic>> getOrderById(String orderId) {
    return _remoteDataSource.getOrderById(orderId);
  }

  @override
  Future<List<dynamic>> getOrders() {
    return _remoteDataSource.getOrders();
  }
}

