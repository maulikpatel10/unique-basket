import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../checkout/presentation/providers/order_provider.dart';

/// Provider that fetches complete order details by order ID / UUID.
final orderDetailsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, orderId) async {
  if (orderId.trim().isEmpty) {
    throw Exception('INVALID_ORDER_ID');
  }
  final repository = ref.watch(orderRepositoryProvider);
  final response = await repository.getOrderById(orderId);
  final dynamic rawData =
      response['order'] ?? (response.containsKey('data') ? response['data'] : response);
  final data = rawData is Map<String, dynamic> ? rawData : null;
  if (data == null || response['success'] == false) {
    throw Exception('ORDER_NOT_FOUND');
  }
  return data;
});
