import '../datasources/cart_remote_data_source.dart';
import '../models/cart_item_model.dart';
import '../models/cart_summary_model.dart';
import '../models/delivery_settings_model.dart';

abstract class CartRepository {
  Future<List<CartItemModel>> getCart();
  Future<CartSummaryModel> getCartSummary();
  Future<DeliverySettingsModel> getDeliverySettings();
  Future<Map<String, dynamic>> addItem({required String productId, required double quantity});
  Future<Map<String, dynamic>> updateItem({required String cartItemId, required double quantity});
  Future<bool> removeItem(String cartItemId);
}

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _remoteDataSource;

  CartRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<CartItemModel>> getCart() {
    return _remoteDataSource.getCart();
  }

  @override
  Future<CartSummaryModel> getCartSummary() {
    return _remoteDataSource.getCartSummary();
  }

  @override
  Future<DeliverySettingsModel> getDeliverySettings() {
    return _remoteDataSource.getDeliverySettings();
  }

  @override
  Future<Map<String, dynamic>> addItem({required String productId, required double quantity}) {
    return _remoteDataSource.addItem(productId: productId, quantity: quantity);
  }

  @override
  Future<Map<String, dynamic>> updateItem({required String cartItemId, required double quantity}) {
    return _remoteDataSource.updateItem(cartItemId: cartItemId, quantity: quantity);
  }

  @override
  Future<bool> removeItem(String cartItemId) {
    return _remoteDataSource.removeItem(cartItemId);
  }
}
