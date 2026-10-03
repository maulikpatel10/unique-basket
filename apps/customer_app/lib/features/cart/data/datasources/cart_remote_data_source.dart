import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/cart_item_model.dart';
import '../models/cart_summary_model.dart';
import '../models/delivery_settings_model.dart';

abstract class CartRemoteDataSource {
  Future<List<CartItemModel>> getCart();
  Future<CartSummaryModel> getCartSummary();
  Future<DeliverySettingsModel> getDeliverySettings();
  Future<Map<String, dynamic>> addItem({required String productId, required double quantity});
  Future<Map<String, dynamic>> updateItem({required String cartItemId, required double quantity});
  Future<bool> removeItem(String cartItemId);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final ApiClient _apiClient;

  CartRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<CartItemModel>> getCart() async {
    final summary = await getCartSummary();
    return summary.items;
  }

  @override
  Future<CartSummaryModel> getCartSummary() async {
    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] CART API REQUEST -> ${ApiEndpoints.cart}');
    }
    try {
      final response = await _apiClient.get(ApiEndpoints.cart);

      dynamic payload = response;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        payload = response['data'];
      }

      if (payload is Map<String, dynamic>) {
        final summary = CartSummaryModel.fromJson(payload);
        if (kDebugMode) {
          debugPrint('[UB-PERSISTENCE] CART API RESPONSE items: ${summary.items.length}, subtotal: ${summary.subtotal}, deliveryFee: ${summary.deliveryFee}, total: ${summary.total}');
        }
        return summary;
      } else if (payload is List) {
        final items = payload
            .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return CartSummaryModel(items: items);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] CART API ERROR: $e');
      }
      // P1-06: never turn a failed request into an empty cart; callers decide how to handle it
      rethrow;
    }
    return const CartSummaryModel();
  }

  @override
  Future<DeliverySettingsModel> getDeliverySettings() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.deliverySettings);
      dynamic payload = response;
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        payload = response['data'];
      }
      if (payload is Map<String, dynamic>) {
        return DeliverySettingsModel.fromJson(payload);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UB-DELIVERY] Failed to fetch delivery settings: $e');
      }
    }
    return const DeliverySettingsModel();
  }

  @override
  Future<Map<String, dynamic>> addItem({
    required String productId,
    required double quantity,
  }) async {
    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] CART ADD API REQUEST: productId=$productId, quantity=$quantity');
    }
    final response = await _apiClient.post(
      '${ApiEndpoints.cart}/items',
      data: {
        'productId': productId,
        'quantity': quantity,
      },
    );

    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] CART ADD API SUCCESS: productId=$productId');
    }

    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> updateItem({
    required String cartItemId,
    required double quantity,
  }) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.cart}/items/$cartItemId',
      data: {
        'quantity': quantity,
      },
    );

    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return <String, dynamic>{};
  }

  @override
  Future<bool> removeItem(String cartItemId) async {
    final response = await _apiClient.delete(
      '${ApiEndpoints.cart}/items/$cartItemId',
    );

    if (response is Map<String, dynamic>) {
      return response['success'] == true;
    }
    return true;
  }
}

