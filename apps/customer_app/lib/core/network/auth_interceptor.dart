import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor responsible for:
/// 1. Attaching Bearer access token to outgoing requests.
/// 2. Intercepting HTTP 401 Unauthorized responses.
/// 3. Performing a single-flight token refresh across concurrent 401s.
/// 4. Retrying the failed request once with the new access token.
/// 5. Safely handling refresh failure (clearing tokens on authentication failure,
///    preserving credentials on transient network/server failures).
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final LocalStorageService? _localStorage;
  final Dio _tokenDio;
  final VoidCallback? _onSessionExpired;

  static const String retryExtraKey = 'authRetry';

  Future<String?>? _refreshFuture;

  AuthInterceptor({
    required SecureStorageService secureStorage,
    required Dio tokenDio,
    LocalStorageService? localStorage,
    VoidCallback? onSessionExpired,
  })  : _secureStorage = secureStorage,
        _tokenDio = tokenDio,
        _localStorage = localStorage,
        _onSessionExpired = onSessionExpired;

  /// Clears credentials and user-scoped data after an authentication failure,
  /// then notifies listeners (router) that the session has expired.
  Future<void> _expireSession() async {
    await _secureStorage.clearTokens();
    await _localStorage?.clearUserSessionData();
    _onSessionExpired?.call();
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Attach Bearer token if present and not already defined
    if (!options.headers.containsKey('Authorization')) {
      final token = await _secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (kDebugMode) {
      debugPrint('[API-REQ] ${options.method} ${options.uri}');
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint('[API-RES] ${response.requestOptions.method} ${response.requestOptions.uri} | Status: ${response.statusCode}');
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final options = err.requestOptions;

    if (kDebugMode) {
      debugPrint('[API-ERR] ${options.method} ${options.uri} | Status: ${response?.statusCode} | Message: ${err.message}');
    }

    // Guard 1: Only intercept 401 Unauthorized status
    // Guard 2: Never re-intercept requests that have already been retried
    // Guard 3: Never intercept the refresh endpoint itself
    if (response?.statusCode != 401 ||
        options.extra[retryExtraKey] == true ||
        options.path == ApiEndpoints.refreshToken) {
      return handler.next(err);
    }

    try {
      final requestAuth = options.headers['Authorization'];
      String? requestToken;

      if (requestAuth is String && requestAuth.startsWith('Bearer ')) {
        requestToken = requestAuth.substring(7);
      }

      // Single-flight refresh: share the ongoing refresh Future across concurrent 401s.
      // _performRefresh freshly validates that the stored token has not already been updated
      // before executing the network refresh request.
      final newAccessToken =
          await (_refreshFuture ??= _performRefresh(requestToken));

      if (newAccessToken == null || newAccessToken.isEmpty) {
        return handler.next(err);
      }

      // Prepare retry: update Authorization header and mark as retried
      options.headers['Authorization'] = 'Bearer $newAccessToken';
      options.extra[retryExtraKey] = true;

      // Replay request using tokenDio (which preserves all request options)
      final retryResponse = await _tokenDio.fetch(options);
      return handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    } catch (_) {
      return handler.next(err);
    }
  }

  Future<String?> _performRefresh(String? failedRequestToken) async {
    try {
      // Fresh boundary check: If storage token is already different from the failed request token,
      // another request has already refreshed the session while this request was in flight or queued.
      final currentToken = await _secureStorage.getAccessToken();
      if (failedRequestToken != null &&
          failedRequestToken.isNotEmpty &&
          currentToken != null &&
          currentToken.isNotEmpty &&
          currentToken != failedRequestToken) {
        return currentToken;
      }

      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.trim().isEmpty) {
        // Missing refresh token is an authentication failure -> clear session
        await _expireSession();
        return null;
      }

      final response = await _tokenDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final dynamic responseData = response.data;
      Map<String, dynamic>? dataMap;
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
          dataMap = responseData['data'] as Map<String, dynamic>;
        } else {
          dataMap = responseData;
        }
      }

      final newAccessToken = (dataMap?['token'] ?? dataMap?['accessToken']) as String?;

      if (newAccessToken == null || newAccessToken.trim().isEmpty) {
        // Response missing usable access token -> authentication failure -> clear session
        await _expireSession();
        return null;
      }

      // Save new access token while preserving the existing refresh token
      await _secureStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
      );

      return newAccessToken;
    } on DioException catch (dioErr) {
      final statusCode = dioErr.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        // Explicit auth rejection -> credentials revoked/expired -> clear session
        await _expireSession();
      }
      // Note: For transient network errors (connection timeout, 5xx, SocketException),
      // we do NOT destroy local credentials.
      return null;
    } catch (_) {
      return null;
    } finally {
      // Always reset the single-flight Future so future token expirations can trigger a new refresh
      _refreshFuture = null;
    }
  }
}
