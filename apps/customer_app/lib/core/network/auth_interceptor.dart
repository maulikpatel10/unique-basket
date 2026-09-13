import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';

/// Generic Authorization interceptor that attaches stored Bearer tokens to outgoing requests.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor({
    required SecureStorageService secureStorage,
  }) : _secureStorage = secureStorage;

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
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint('[API-ERR] ${err.requestOptions.method} ${err.requestOptions.uri} | Status: ${err.response?.statusCode} | Message: ${err.message}');
    }
    handler.next(err);
  }
}
