import 'dart:convert';
import 'dart:typed_data';

import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/app_router.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/core/constants/api_endpoints.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/network/api_client.dart';
import 'package:customer_app/core/session/session_expiry_notifier.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// P1-07: route guard + session-expiry handling.
class _MemorySecureStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    _data[AppConstants.keyAccessToken] = accessToken;
    if (refreshToken != null) _data[AppConstants.keyRefreshToken] = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _data[AppConstants.keyAccessToken];

  @override
  Future<String?> getRefreshToken() async => _data[AppConstants.keyRefreshToken];

  @override
  Future<void> clearTokens() async {
    _data.remove(AppConstants.keyAccessToken);
    _data.remove(AppConstants.keyRefreshToken);
  }

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clearAll() async => _data.clear();
}

class _FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> data, int status) => ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppConfig.initialize(appName: 'Unique Basket', environment: Environment.development);
  });

  group('authRedirect', () {
    test('allows public routes without a session', () async {
      final storage = _MemorySecureStorage();
      for (final route in publicRoutes) {
        expect(await authRedirect(storage, route), isNull, reason: route);
      }
    });

    test('sends protected routes to login when there is no access token', () async {
      final storage = _MemorySecureStorage();
      for (final route in [RouteNames.home, RouteNames.cart, RouteNames.checkout, RouteNames.myOrders, RouteNames.profile]) {
        expect(await authRedirect(storage, route), RouteNames.mobileNumber, reason: route);
      }
    });

    test('allows protected routes when an access token exists', () async {
      final storage = _MemorySecureStorage();
      await storage.saveTokens(accessToken: 'access', refreshToken: 'refresh');
      expect(await authRedirect(storage, RouteNames.cart), isNull);
    });

    test('dev-only routes are not public', () {
      expect(publicRoutes.contains(RouteNames.devProfileSetup), isFalse);
      expect(publicRoutes.contains(RouteNames.devFirstTimeAddAddress), isFalse);
    });
  });

  group('AuthInterceptor session expiry callback', () {
    Future<int> runWithRefreshStatus(int refreshStatus) async {
      final storage = _MemorySecureStorage();
      await storage.saveTokens(accessToken: 'expired', refreshToken: 'refresh');
      var expiries = 0;

      final adapter = _FakeAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          return _json({'success': false}, refreshStatus);
        }
        return _json({'success': false}, 401);
      });
      final client = ApiClient(
        secureStorage: storage,
        dio: Dio()..httpClientAdapter = adapter,
        tokenDio: Dio()..httpClientAdapter = adapter,
        onSessionExpired: () => expiries++,
      );

      try {
        await client.get('/orders');
      } catch (_) {}
      return expiries;
    }

    test('notifies once when the refresh token is rejected (401)', () async {
      expect(await runWithRefreshStatus(401), 1);
    });

    test('does not notify on a transient refresh failure (5xx)', () async {
      expect(await runWithRefreshStatus(503), 0);
    });
  });

  testWidgets('an expired session moves the user from a protected screen to login', (tester) async {
    final storage = _MemorySecureStorage();
    await storage.saveTokens(accessToken: 'access', refreshToken: 'refresh');
    final sessionExpiry = SessionExpiryNotifier();

    final router = GoRouter(
      initialLocation: RouteNames.cart,
      refreshListenable: sessionExpiry,
      redirect: (context, state) => authRedirect(storage, state.matchedLocation),
      routes: [
        GoRoute(path: RouteNames.cart, builder: (_, __) => const Text('CART SCREEN')),
        GoRoute(path: RouteNames.mobileNumber, builder: (_, __) => const Text('LOGIN SCREEN')),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('CART SCREEN'), findsOneWidget);

    // Interceptor cleared the session after the refresh token was rejected
    await storage.clearTokens();
    sessionExpiry.notifySessionExpired();
    await tester.pumpAndSettle();

    expect(find.text('LOGIN SCREEN'), findsOneWidget);
    expect(find.text('CART SCREEN'), findsNothing);
  });
}
