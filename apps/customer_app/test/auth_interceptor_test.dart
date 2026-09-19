import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/core/constants/api_endpoints.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/errors/app_exception.dart';
import 'package:customer_app/core/network/api_client.dart';
import 'package:customer_app/core/network/auth_interceptor.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSecureStorageService implements SecureStorageService {
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

/// Fake HttpClientAdapter to deterministically mock responses and capture request telemetry.
class FakeHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  FakeHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponseBody(Map<String, dynamic> data, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSecureStorageService secureStorage;

  setUpAll(() {
    AppConfig.initialize(
      appName: 'Unique Basket',
      environment: Environment.development,
    );
  });

  setUp(() {
    secureStorage = MockSecureStorageService();
  });

  group('Phase 2 — Runtime 401 Refresh & Retry Tests', () {
    test('1. Valid authenticated request -> 200, no refresh called', () async {
      await secureStorage.saveTokens(
        accessToken: 'valid_access_token',
        refreshToken: 'valid_refresh_token',
      );

      int refreshCallCount = 0;
      int apiCallCount = 0;

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          refreshCallCount++;
          return jsonResponseBody({'success': true, 'data': {'token': 'new_token'}}, 200);
        }
        apiCallCount++;
        expect(options.headers['Authorization'], equals('Bearer valid_access_token'));
        return jsonResponseBody({'success': true, 'data': {'profile': 'user'}}, 200);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      final result = await apiClient.get('/test-endpoint');
      expect(result, equals({'profile': 'user'}));
      expect(apiCallCount, equals(1));
      expect(refreshCallCount, equals(0));
    });

    test('2 & 3 & 4. 401 -> refresh -> retry -> 200, saves new token & preserves refresh token', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'valid_refresh_token_xyz',
      );

      int refreshCallCount = 0;
      int apiCallCount = 0;

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          refreshCallCount++;
          expect(options.data, equals({'refreshToken': 'valid_refresh_token_xyz'}));
          return jsonResponseBody({'success': true, 'data': {'token': 'new_refreshed_access_token'}}, 200);
        }
        apiCallCount++;
        if (apiCallCount == 1) {
          expect(options.headers['Authorization'], equals('Bearer expired_access_token'));
          return jsonResponseBody({'success': false, 'message': 'Token expired.'}, 401);
        } else {
          // Retried call
          expect(options.headers['Authorization'], equals('Bearer new_refreshed_access_token'));
          expect(options.extra[AuthInterceptor.retryExtraKey], isTrue);
          return jsonResponseBody({'success': true, 'data': {'orderId': 'ord_123'}}, 200);
        }
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      final result = await apiClient.get('/orders/123');
      expect(result, equals({'orderId': 'ord_123'}));
      expect(refreshCallCount, equals(1));
      expect(apiCallCount, equals(2));

      // 3. New access token is saved
      expect(await secureStorage.getAccessToken(), equals('new_refreshed_access_token'));
      // 4. Refresh token is preserved
      expect(await secureStorage.getRefreshToken(), equals('valid_refresh_token_xyz'));
    });

    test('5. Retried request receives 401 again -> no second refresh, throws UnauthorizedException', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_token',
        refreshToken: 'valid_refresh_token',
      );

      int refreshCallCount = 0;
      int apiCallCount = 0;

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          refreshCallCount++;
          return jsonResponseBody({'success': true, 'data': {'token': 'new_token'}}, 200);
        }
        apiCallCount++;
        // Always returns 401
        return jsonResponseBody({'success': false, 'message': 'Still unauthorized.'}, 401);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      expect(
        () => apiClient.get('/protected'),
        throwsA(isA<UnauthorizedException>()),
      );

      // Give event loop time to process
      await Future.delayed(const Duration(milliseconds: 50));

      expect(refreshCallCount, equals(1));
      expect(apiCallCount, equals(2)); // Original + 1 retry, NOT 3+
    });

    test('6. Refresh endpoint returning 401 does not recursively refresh', () async {
      await secureStorage.saveTokens(
        accessToken: 'some_access_token',
        refreshToken: 'revoked_refresh_token',
      );

      int refreshCallCount = 0;

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          refreshCallCount++;
          return jsonResponseBody({'success': false, 'message': 'Refresh token revoked.'}, 401);
        }
        return jsonResponseBody({'success': false, 'message': 'Unauthorized.'}, 401);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      expect(
        () => apiClient.get('/profile'),
        throwsA(isA<UnauthorizedException>()),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(refreshCallCount, equals(1)); // Stopped immediately at 1, no recursion
    });

    test('7. Missing refresh token -> tokens cleared -> authentication failure', () async {
      await secureStorage.saveTokens(accessToken: 'orphan_access_token');

      int refreshCallCount = 0;

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          refreshCallCount++;
          return jsonResponseBody({'success': true, 'data': {'token': 'new_token'}}, 200);
        }
        return jsonResponseBody({'success': false, 'message': 'Unauthorized.'}, 401);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      expect(
        () => apiClient.get('/dashboard'),
        throwsA(isA<UnauthorizedException>()),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(refreshCallCount, equals(0)); // Cannot refresh without refresh token
      expect(await secureStorage.getAccessToken(), isNull);
      expect(await secureStorage.getRefreshToken(), isNull);
    });

    test('8. Refresh returns 401 -> tokens cleared -> authentication failure', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_access',
        refreshToken: 'invalid_refresh',
      );

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          return jsonResponseBody({'success': false, 'message': 'Invalid refresh.'}, 401);
        }
        return jsonResponseBody({'success': false, 'message': 'Unauthorized.'}, 401);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      expect(
        () => apiClient.get('/user'),
        throwsA(isA<UnauthorizedException>()),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(await secureStorage.getAccessToken(), isNull);
      expect(await secureStorage.getRefreshToken(), isNull);
    });

    test('9. Refresh returns unusable/missing access token -> tokens cleared', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_access',
        refreshToken: 'valid_refresh',
      );

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          return jsonResponseBody({'success': true, 'data': {}}, 200); // Missing 'token' field
        }
        return jsonResponseBody({'success': false, 'message': 'Unauthorized.'}, 401);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      expect(
        () => apiClient.get('/user'),
        throwsA(isA<UnauthorizedException>()),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(await secureStorage.getAccessToken(), isNull);
      expect(await secureStorage.getRefreshToken(), isNull);
    });

    test('10. Refresh timeout -> does NOT clear refresh token', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_access',
        refreshToken: 'saved_refresh_token',
      );

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
            message: 'Connection timed out',
          );
        }
        return jsonResponseBody({'success': false, 'message': 'Unauthorized.'}, 401);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      expect(
        () => apiClient.get('/catalog'),
        throwsA(isA<UnauthorizedException>()),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      // Refresh token must NOT be destroyed by network timeout
      expect(await secureStorage.getRefreshToken(), equals('saved_refresh_token'));
    });

    test('11. Refresh network failure -> does NOT clear refresh token', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_access',
        refreshToken: 'saved_refresh_token',
      );

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'Network unreachable',
          );
        }
        return jsonResponseBody({'success': false, 'message': 'Unauthorized.'}, 401);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      expect(
        () => apiClient.get('/catalog'),
        throwsA(isA<UnauthorizedException>()),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(await secureStorage.getRefreshToken(), equals('saved_refresh_token'));
    });

    test('12. Refresh 5xx server error -> does NOT destroy session credentials', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_access',
        refreshToken: 'saved_refresh_token',
      );

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          return jsonResponseBody({'success': false, 'message': 'Internal server error.'}, 500);
        }
        return jsonResponseBody({'success': false, 'message': 'Unauthorized.'}, 401);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      expect(
        () => apiClient.get('/catalog'),
        throwsA(isA<UnauthorizedException>()),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(await secureStorage.getRefreshToken(), equals('saved_refresh_token'));
    });

    test('13 & 14 & 15. Five simultaneous 401s -> exactly ONE refresh request, all 5 retry & succeed', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_token',
        refreshToken: 'concurrent_refresh_token',
      );

      int refreshCallCount = 0;
      final Map<String, int> callCounts = {};

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          refreshCallCount++;
          // Simulate network latency on refresh call
          await Future.delayed(const Duration(milliseconds: 30));
          return jsonResponseBody({'success': true, 'data': {'token': 'shared_new_access_token'}}, 200);
        }

        final path = options.path;
        callCounts[path] = (callCounts[path] ?? 0) + 1;

        if (callCounts[path] == 1) {
          // First attempt returns 401
          return jsonResponseBody({'success': false, 'message': 'Token expired'}, 401);
        } else {
          // Retry attempt
          expect(options.headers['Authorization'], equals('Bearer shared_new_access_token'));
          expect(options.extra[AuthInterceptor.retryExtraKey], isTrue);
          return jsonResponseBody({'success': true, 'data': {'item': path}}, 200);
        }
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      // Launch 5 concurrent requests simultaneously
      final futures = [
        apiClient.get('/req-1'),
        apiClient.get('/req-2'),
        apiClient.get('/req-3'),
        apiClient.get('/req-4'),
        apiClient.get('/req-5'),
      ];

      final results = await Future.wait(futures);

      // Assert all 5 succeeded
      expect(results.length, equals(5));
      expect(results[0], equals({'item': '/req-1'}));
      expect(results[1], equals({'item': '/req-2'}));
      expect(results[2], equals({'item': '/req-3'}));
      expect(results[3], equals({'item': '/req-4'}));
      expect(results[4], equals({'item': '/req-5'}));

      // Mandatory assertion: Exactly ONE refresh call made
      expect(refreshCallCount, equals(1));
      // Each of the 5 requests made 2 calls (initial + retry)
      for (final key in ['/req-1', '/req-2', '/req-3', '/req-4', '/req-5']) {
        expect(callCounts[key], equals(2));
      }
    });

    test('16. Concurrent refresh failure -> all waiting requests fail consistently', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_token',
        refreshToken: 'failing_refresh_token',
      );

      int refreshCallCount = 0;

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          refreshCallCount++;
          await Future.delayed(const Duration(milliseconds: 20));
          return jsonResponseBody({'success': false, 'message': 'Refresh token invalid.'}, 401);
        }
        return jsonResponseBody({'success': false, 'message': 'Unauthorized.'}, 401);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      final futures = [
        apiClient.get('/parallel-1'),
        apiClient.get('/parallel-2'),
        apiClient.get('/parallel-3'),
      ];

      for (final future in futures) {
        expect(future, throwsA(isA<UnauthorizedException>()));
      }

      await Future.delayed(const Duration(milliseconds: 60));
      expect(refreshCallCount, equals(1));
      expect(await secureStorage.getAccessToken(), isNull);
      expect(await secureStorage.getRefreshToken(), isNull);
    });

    test('17. Request arriving during refresh joins existing refresh operation', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_token',
        refreshToken: 'valid_refresh_token',
      );

      int refreshCallCount = 0;
      final Map<String, int> callCounts = {};

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          refreshCallCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return jsonResponseBody({'success': true, 'data': {'token': 'late_arrival_access_token'}}, 200);
        }

        final path = options.path;
        callCounts[path] = (callCounts[path] ?? 0) + 1;

        if (callCounts[path] == 1) {
          return jsonResponseBody({'success': false, 'message': 'Token expired'}, 401);
        } else {
          expect(options.headers['Authorization'], equals('Bearer late_arrival_access_token'));
          return jsonResponseBody({'success': true, 'data': {'path': path}}, 200);
        }
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      // Request A starts and initiates refresh
      final futureA = apiClient.get('/early-req');

      // Request B arrives 20ms later while refresh is in-flight
      await Future.delayed(const Duration(milliseconds: 20));
      final futureB = apiClient.get('/late-req');

      final results = await Future.wait([futureA, futureB]);
      expect(results[0], equals({'path': '/early-req'}));
      expect(results[1], equals({'path': '/late-req'}));
      expect(refreshCallCount, equals(1));
    });

    test('18. GET request retains query parameters after retry', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_token',
        refreshToken: 'valid_refresh',
      );

      int apiCallCount = 0;

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          return jsonResponseBody({'success': true, 'data': {'token': 'new_access_token'}}, 200);
        }
        apiCallCount++;
        if (apiCallCount == 1) {
          return jsonResponseBody({'success': false}, 401);
        }
        // Verify query parameters are preserved on retry
        expect(options.queryParameters, equals({'category': 'dairy', 'page': '1'}));
        return jsonResponseBody({'success': true, 'data': {'products': ['milk', 'butter']}}, 200);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      final result = await apiClient.get('/products', queryParameters: {'category': 'dairy', 'page': '1'});
      expect(result, equals({'products': ['milk', 'butter']}));
      expect(apiCallCount, equals(2));
    });

    test('19. POST request retains request body after retry', () async {
      await secureStorage.saveTokens(
        accessToken: 'expired_token',
        refreshToken: 'valid_refresh',
      );

      int apiCallCount = 0;

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          return jsonResponseBody({'success': true, 'data': {'token': 'new_access_token'}}, 200);
        }
        apiCallCount++;
        if (apiCallCount == 1) {
          return jsonResponseBody({'success': false}, 401);
        }
        // Verify JSON payload is preserved on retry
        expect(options.data, equals({'itemId': 'item_999', 'quantity': 2}));
        return jsonResponseBody({'success': true, 'data': {'cartTotal': 150.0}}, 200);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      final result = await apiClient.post('/cart/items', data: {'itemId': 'item_999', 'quantity': 2});
      expect(result, equals({'cartTotal': 150.0}));
      expect(apiCallCount, equals(2));
    });

    test('Post-refresh boundary race: Request A & B both sent with Token_V1, B 401 delayed until after A refresh finishes -> B retries with Token_V2 without second refresh', () async {
      await secureStorage.saveTokens(
        accessToken: 'Token_V1',
        refreshToken: 'valid_refresh_token',
      );

      int refreshCallCount = 0;
      final Map<String, int> callCounts = {};
      final Completer<void> reqBSent = Completer<void>();
      final Completer<void> reqBRelease401 = Completer<void>();

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          refreshCallCount++;
          return jsonResponseBody({'success': true, 'data': {'token': 'Token_V2'}}, 200);
        }

        final path = options.path;
        callCounts[path] = (callCounts[path] ?? 0) + 1;

        if (path == '/req-a') {
          if (callCounts[path] == 1) {
            expect(options.headers['Authorization'], equals('Bearer Token_V1'));
            return jsonResponseBody({'success': false, 'message': 'Token expired'}, 401);
          } else {
            expect(options.headers['Authorization'], equals('Bearer Token_V2'));
            expect(options.extra[AuthInterceptor.retryExtraKey], isTrue);
            return jsonResponseBody({'success': true, 'data': {'result': 'a_success'}}, 200);
          }
        } else if (path == '/req-b') {
          if (callCounts[path] == 1) {
            // Step 1: Request B sent with Token_V1
            expect(options.headers['Authorization'], equals('Bearer Token_V1'));
            if (!reqBSent.isCompleted) {
              reqBSent.complete();
            }
            // Step 4: Deliberately delay B's 401 until Request A completes refresh
            await reqBRelease401.future;
            return jsonResponseBody({'success': false, 'message': 'Token expired'}, 401);
          } else {
            // Step 9: Retried call MUST use Token_V2
            expect(options.headers['Authorization'], equals('Bearer Token_V2'));
            expect(options.extra[AuthInterceptor.retryExtraKey], isTrue);
            return jsonResponseBody({'success': true, 'data': {'result': 'b_success'}}, 200);
          }
        }
        return jsonResponseBody({'success': false}, 404);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      // Step 1: Both Request A and Request B leave client with Token_V1
      final futureA = apiClient.get('/req-a');
      final futureB = apiClient.get('/req-b');

      // Wait until Request B has been dispatched with Token_V1
      await reqBSent.future;

      // Step 2, 3, 5, 6: Request A receives 401, starts refresh, refresh finishes (Token_V2), _refreshFuture becomes null
      final resultA = await futureA;
      expect(resultA, equals({'result': 'a_success'}));
      expect(refreshCallCount, equals(1));
      expect(await secureStorage.getAccessToken(), equals('Token_V2'));

      // Step 7: B's delayed 401 now arrives after A's refresh completed and _refreshFuture is null
      reqBRelease401.complete();

      // Step 8, 9: B detects its failed token (Token_V1) != storage (Token_V2) -> retries with Token_V2
      final resultB = await futureB;
      expect(resultB, equals({'result': 'b_success'}));

      // Step 10: refreshCallCount MUST remain exactly 1 (no second refresh!)
      expect(refreshCallCount, equals(1));
    });

    test('Genuinely later expiration: request sent with current token receiving 401 triggers new refresh request', () async {
      await secureStorage.saveTokens(
        accessToken: 'token_v2',
        refreshToken: 'valid_refresh',
      );

      int refreshCallCount = 0;
      int apiCallCount = 0;

      final adapter = FakeHttpClientAdapter((options) async {
        if (options.path.contains(ApiEndpoints.refreshToken)) {
          refreshCallCount++;
          return jsonResponseBody({'success': true, 'data': {'token': 'token_v3'}}, 200);
        }

        apiCallCount++;
        if (apiCallCount == 1) {
          expect(options.headers['Authorization'], equals('Bearer token_v2'));
          return jsonResponseBody({'success': false, 'message': 'Token v2 expired'}, 401);
        } else {
          expect(options.headers['Authorization'], equals('Bearer token_v3'));
          return jsonResponseBody({'success': true, 'data': {'data': 'v3_success'}}, 200);
        }
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final tokenDio = Dio()..httpClientAdapter = adapter;
      final apiClient = ApiClient(
        secureStorage: secureStorage,
        dio: dio,
        tokenDio: tokenDio,
      );

      final result = await apiClient.get('/future-call');
      expect(result, equals({'data': 'v3_success'}));
      expect(refreshCallCount, equals(1));
      expect(apiCallCount, equals(2));
      expect(await secureStorage.getAccessToken(), equals('token_v3'));
    });
  });
}
