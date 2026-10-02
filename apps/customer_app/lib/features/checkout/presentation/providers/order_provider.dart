import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/repositories/order_repository.dart';

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderRemoteDataSourceImpl(apiClient);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final remoteDataSource = ref.watch(orderRemoteDataSourceProvider);
  return OrderRepositoryImpl(remoteDataSource);
});

/// Provider to fetch all customer orders.
final customerOrdersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  try {
    return await repository.getOrders();
  } catch (_) {
    return [];
  }
});

/// Provider for total count of customer orders.
final customerOrdersCountProvider = Provider<int>((ref) {
  final ordersAsync = ref.watch(customerOrdersProvider);
  return ordersAsync.valueOrNull?.length ?? 0;
});

enum CheckoutPaymentMethod {

  upi,
  cod,
}

final selectedPaymentMethodProvider =
    StateProvider<CheckoutPaymentMethod>((ref) => CheckoutPaymentMethod.upi);
