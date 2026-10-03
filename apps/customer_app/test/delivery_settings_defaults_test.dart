import 'package:customer_app/features/cart/data/models/cart_summary_model.dart';
import 'package:customer_app/features/cart/data/models/delivery_settings_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-009: fallbacks match the confirmed values; backend values always win.
void main() {
  test('DeliverySettingsModel falls back to the confirmed values', () {
    final settings = DeliverySettingsModel.fromJson(const {});
    expect(settings.deliveryFee, 30.0);
    expect(settings.freeDeliveryThreshold, 200.0);
    expect(settings.minimumOrderAmount, 199.0);
    expect(const DeliverySettingsModel().freeDeliveryThreshold, 200.0);
  });

  test('backend-provided values override the fallbacks', () {
    final settings = DeliverySettingsModel.fromJson(const {
      'deliveryFee': '45',
      'freeDeliveryThreshold': 750,
      'minimumOrderAmount': 250.5,
    });
    expect(settings.deliveryFee, 45.0);
    expect(settings.freeDeliveryThreshold, 750.0);
    expect(settings.minimumOrderAmount, 250.5);
  });

  test('CartSummaryModel uses the confirmed free-delivery threshold as fallback', () {
    expect(CartSummaryModel.fromJson(const {}).freeDeliveryThreshold, 200.0);
    expect(const CartSummaryModel().freeDeliveryThreshold, 200.0);
    expect(CartSummaryModel.fromJson(const {'freeDeliveryThreshold': 300}).freeDeliveryThreshold, 300.0);
  });
}
