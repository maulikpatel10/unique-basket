import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/cart/data/repositories/cart_repository.dart';
import 'package:customer_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P1-06: failed cart writes are surfaced and reconciled with the server cart.
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

class _ServerCart implements CartRepository {
  final Map<String, int> server;
  bool failWrites;
  _ServerCart(this.server, {this.failWrites = false});

  List<CartItemModel> get _items => server.entries
      .map((e) => CartItemModel(id: 'ci_${e.key}', productId: e.key, price: 10, quantity: e.value, totalPrice: 10.0 * e.value))
      .toList();

  @override
  Future<List<CartItemModel>> getCart() async => _items;
  @override
  Future<CartSummaryModel> getCartSummary() async => CartSummaryModel(items: _items);
  @override
  Future<DeliverySettingsModel> getDeliverySettings() async => const DeliverySettingsModel();
  @override
  Future<Map<String, dynamic>> addItem({required String productId, required int quantity}) async {
    if (failWrites) throw Exception('server rejected');
    server[productId] = quantity;
    return {'id': 'ci_$productId'};
  }

  @override
  Future<Map<String, dynamic>> updateItem({required String cartItemId, required int quantity}) async {
    if (failWrites) throw Exception('server rejected');
    server[cartItemId.replaceFirst('ci_', '')] = quantity;
    return {};
  }

  @override
  Future<bool> removeItem(String cartItemId) async {
    if (failWrites) throw Exception('server rejected');
    server.remove(cartItemId.replaceFirst('ci_', ''));
    return true;
  }
}

void main() {
  setUp(() {
    AppConfig.initialize(appName: 'Unique Basket', environment: Environment.development);
  });

  Future<(ProviderContainer, CartStateNotifier)> build(_ServerCart repo) async {
    SharedPreferences.setMockInitialValues({});
    final localStorage = LocalStorageService(await SharedPreferences.getInstance());
    late CartStateNotifier notifier;
    final provider = StateNotifierProvider<CartStateNotifier, Map<String, int>>((ref) {
      notifier = CartStateNotifier(
        ref: ref,
        cartRepository: repo,
        localStorage: localStorage,
        secureStorage: _TokenStorage(),
      );
      return notifier;
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(provider, (_, __) {});
    await Future<void>.delayed(Duration.zero);
    await notifier.loadCart();
    return (container, notifier);
  }

  test('a rejected add rolls back to the server cart and reports an error', () async {
    final repo = _ServerCart({'apple': 1}, failWrites: true);
    final (container, notifier) = await build(repo);
    expect(notifier.state, {'apple': 1});

    notifier.increment('banana');
    expect(notifier.state['banana'], 1); // optimistic

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(notifier.state, {'apple': 1}); // reconciled with server
    expect(container.read(cartSyncErrorProvider), cartSyncFailedMessage);
  });

  test('a rejected quantity change restores the server quantity', () async {
    final repo = _ServerCart({'apple': 2});
    final (container, notifier) = await build(repo);
    repo.failWrites = true;

    notifier.increment('apple');
    expect(notifier.state['apple'], 3);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state['apple'], 2);
    expect(container.read(cartSyncErrorProvider), isNotNull);
  });

  test('successful writes do not report errors', () async {
    final repo = _ServerCart({});
    final (container, notifier) = await build(repo);

    notifier.increment('kiwi');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repo.server['kiwi'], 1);
    expect(notifier.state['kiwi'], 1);
    expect(container.read(cartSyncErrorProvider), isNull);
    expect(AppConstants.keyUserCart, isNotEmpty);
  });
}
