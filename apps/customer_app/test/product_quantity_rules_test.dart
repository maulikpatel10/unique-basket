import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/cart/data/repositories/cart_repository.dart';
import 'package:customer_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/shared/widgets/product_quantity_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// D-012: quantity rules are product-level and admin-configurable.
ProductModel _product(String id, String unit, {double? min, double? max, double? step}) => ProductModel(
      id: id,
      categoryId: 'c',
      name: id,
      price: 10,
      unit: unit,
      minQuantity: min,
      maxQuantity: max,
      quantityStep: step,
    );

final potato = _product('potato', 'KG', min: 1, max: 10, step: 0.25);
final apple = _product('apple', 'KG', min: 0.5, max: 5, step: 0.25);
final berries = _product('berries', 'GRAM', min: 250, max: 2000, step: 250);
final cherries = _product('cherries', 'GRAM', min: 100, max: 1000, step: 50);
final coconut = _product('coconut', 'PIECE', min: 1, max: 10, step: 1);

class _TokenStorage implements SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'access';
  @override
  Future<String?> getRefreshToken() async => 'refresh';
  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {}
  @override
  Future<void> clearTokens() async {}
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> clearAll() async {}
}

class _RecordingCart implements CartRepository {
  final List<double> sent = [];
  @override
  Future<List<CartItemModel>> getCart() async => [];
  @override
  Future<CartSummaryModel> getCartSummary() async => const CartSummaryModel();
  @override
  Future<DeliverySettingsModel> getDeliverySettings() async => const DeliverySettingsModel();
  @override
  Future<Map<String, dynamic>> addItem({required String productId, required double quantity}) async {
    sent.add(quantity);
    return {'id': 'ci_$productId'};
  }

  @override
  Future<Map<String, dynamic>> updateItem({required String cartItemId, required double quantity}) async {
    sent.add(quantity);
    return {};
  }

  @override
  Future<bool> removeItem(String cartItemId) async => true;
}

void main() {
  group('QuantityRule', () {
    test('KG product with a 1 KG minimum starts at 1 and steps by 0.25', () {
      final rule = potato.quantityRule;
      expect(rule.next(0), 1);
      expect(rule.next(1), 1.25);
      expect(rule.previous(1.25), 1);
      expect(rule.previous(1), 0, reason: 'below the minimum removes the line');
    });

    test('KG product with a 0.5 KG minimum (not every KG product starts at 0.25 or 1)', () {
      final rule = apple.quantityRule;
      expect(rule.next(0), 0.5);
      expect(rule.next(0.5), 0.75);
      expect(rule.validate(0.25), contains('Minimum is 0.5 kg'));
    });

    test('KG step and maximum validation; boundaries accepted', () {
      final rule = potato.quantityRule;
      expect(rule.validate(1), isNull);
      expect(rule.validate(10), isNull);
      expect(rule.validate(1.3), contains('steps of 0.25 kg'));
      expect(rule.validate(10.25), contains('Maximum is 10 kg'));
      expect(rule.validate(0.75), contains('Minimum is 1 kg'));
      expect(rule.next(10), isNull);
      expect(rule.canIncrement(9.75), isTrue);
      expect(rule.canIncrement(10), isFalse);
    });

    test('repeated steps stay exact (no floating point drift)', () {
      final rule = potato.quantityRule;
      double q = 0;
      for (var i = 0; i < 37; i++) {
        q = rule.next(q)!;
      }
      expect(q, 10);
      expect(rule.validate(q), isNull);
    });

    test('GRAM product with a 250 G step', () {
      final rule = berries.quantityRule;
      expect(rule.next(0), 250);
      expect(rule.next(250), 500);
      expect(rule.validate(2000), isNull);
      expect(rule.validate(300), contains('steps of 250 g'));
      expect(rule.validate(2250), contains('Maximum'));
      expect(rule.validate(250.5), contains('whole number'));
    });

    test('GRAM product with a different configured minimum and step', () {
      final rule = cherries.quantityRule;
      expect(rule.next(0), 100);
      expect(rule.next(100), 150);
      expect(rule.validate(50), contains('Minimum is 100 g'));
    });

    test('PIECE product only accepts whole numbers', () {
      final rule = coconut.quantityRule;
      expect(rule.next(0), 1);
      expect(rule.next(9), 10);
      expect(rule.next(10), isNull);
      expect(rule.validate(1.5), contains('whole number'));
      expect(rule.validate(3), isNull);
    });

    test('PACK and DOZEN quantities must be whole numbers, configured or not', () {
      expect(_product('spinach', 'PACK', min: 1, max: 6, step: 1).quantityRule.validate(1.5), contains('whole number'));
      expect(_product('banana', 'DOZEN').quantityRule.validate(0.5), contains('whole number'));
      expect(_product('banana', 'DOZEN').quantityRule.validate(2), isNull);
    });

    test('unconfigured products keep the previous behaviour (start at 1, step 1, no max)', () {
      final rule = _product('legacy', 'KG').quantityRule;
      expect(rule.isConfigured, isFalse);
      expect(rule.next(0), 1);
      expect(rule.next(7), 8);
      expect(rule.validate(0.3), isNull);
      expect(rule.limitsLabel, isNull);
      expect(_product('legacy_piece', 'PIECE').quantityRule.validate(1.5), contains('whole number'));
    });

    test('displays limits and formats quantities', () {
      expect(potato.quantityRule.limitsLabel, 'Min 1 kg · Max 10 kg · Step 0.25 kg');
      expect(berries.quantityRule.limitsLabel, 'Min 250 g · Max 2000 g · Step 250 g');
      expect(QuantityRule.format(1.25), '1.25');
      expect(QuantityRule.format(2), '2');
      expect(QuantityRule.format(0.5), '0.5');
    });
  });

  group('API parsing', () {
    test('ProductModel reads min/max/step (numbers or decimal strings)', () {
      final p = ProductModel.fromJson(const {
        'id': 'p1',
        'name': 'Potato',
        'price': '30.00',
        'unit': 'KG',
        'minQuantity': '1.000',
        'maxQuantity': 10,
        'quantityStep': '0.250',
      });
      expect(p.quantityRule.isConfigured, isTrue);
      expect(p.quantityRule.min, 1);
      expect(p.quantityRule.max, 10);
      expect(p.quantityRule.step, 0.25);
    });

    test('CartItemModel keeps decimal quantities (no int truncation) and rule values', () {
      final item = CartItemModel.fromJson(const {
        'id': 'ci1',
        'productId': 'p1',
        'price': 30,
        'quantity': 1.25,
        'minQuantity': 1,
        'maxQuantity': 10,
        'quantityStep': 0.25,
      });
      expect(item.quantity, 1.25);
      expect(item.quantityStep, 0.25);
    });
  });

  group('Cart', () {
    Future<(CartStateNotifier, _RecordingCart)> build({Map<String, Object>? cached, bool signedIn = true}) async {
      SharedPreferences.setMockInitialValues(cached ?? {});
      final localStorage = LocalStorageService(await SharedPreferences.getInstance());
      final repo = _RecordingCart();
      final notifier = CartStateNotifier(
        cartRepository: repo,
        localStorage: localStorage,
        secureStorage: signedIn ? _TokenStorage() : null,
      );
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);
      return (notifier, repo);
    }

    test('+/- follow each product rule and sync decimal quantities to the backend', () async {
      final (cart, repo) = await build();
      cart.increment(potato.id, rule: potato.quantityRule);
      cart.increment(potato.id, rule: potato.quantityRule);
      cart.increment(berries.id, rule: berries.quantityRule);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cart.state, {'potato': 1.25, 'berries': 250});
      expect(repo.sent, containsAll([1.0, 1.25, 250.0]));

      cart.decrement(potato.id, rule: potato.quantityRule);
      expect(cart.state['potato'], 1);
      cart.decrement(potato.id, rule: potato.quantityRule);
      expect(cart.state.containsKey('potato'), isFalse);
    });

    test('does not exceed the configured maximum', () async {
      final (cart, _) = await build();
      cart.setItemQuantity(coconut.id, 10);
      cart.increment(coconut.id, rule: coconut.quantityRule);
      expect(cart.state['coconut'], 10);
    });

    test('cart badge counts product lines, not quantity (2 kg potatoes + 5 apples = 2 items)', () async {
      final (cart, _) = await build();
      cart.setCart({'potato': 2, 'apple_piece': 5});
      expect(cart.totalItemCount, 2);
    });

    test('restores decimal quantities from the local cache', () async {
      // Signed out: no server reconciliation, so the cached cart is shown as-is
      final (cart, _) = await build(cached: {AppConstants.keyUserCart: '{"potato":1.75,"coconut":2}'}, signedIn: false);
      expect(cart.state, {'potato': 1.75, 'coconut': 2});
    });
  });

  group('ProductQuantityControl', () {
    testWidgets('shows decimal quantities and ignores "+" at the maximum', (tester) async {
      var increments = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProductQuantityControl(quantity: 1.25, onIncrement: () => increments++),
          ),
        ),
      ));
      expect(find.text('1.25'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(increments, 1);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProductQuantityControl(quantity: 10, canIncrement: false, onIncrement: () => increments++),
          ),
        ),
      ));
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(increments, 1);
      expect(find.bySemanticsLabel('Maximum quantity reached'), findsOneWidget);
    });
  });
}
