import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/core/constants/api_endpoints.dart';
import 'package:customer_app/core/network/api_client.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';

void main() {
  setUp(() {
    AppConfig.initialize(
      appName: 'Unique Basket',
      environment: Environment.development,
      customBaseUrl: 'http://localhost:5001/api/v1',
    );
  });

  test('ApiClient initializes with correct BaseOptions and headers', () {
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);

    expect(apiClient.dio.options.baseUrl, equals('http://localhost:5001/api/v1'));
    expect(apiClient.dio.options.headers['Content-Type'], equals('application/json'));
    expect(apiClient.dio.options.headers['Accept'], equals('application/json'));
    expect(apiClient.dio.options.connectTimeout, equals(const Duration(seconds: 15)));
  });

  test('Resolved URI for Send OTP does NOT contain duplicated /api/v1', () {
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);

    final resolvedUri = apiClient.dio.options.baseUrl.endsWith('/')
        ? '${apiClient.dio.options.baseUrl}${ApiEndpoints.sendOtp.substring(1)}'
        : '${apiClient.dio.options.baseUrl}${ApiEndpoints.sendOtp}';

    expect(resolvedUri, equals('http://localhost:5001/api/v1/auth/send-otp'));
    expect(resolvedUri, isNot(contains('/api/v1/api/v1')));
  });

  test('Resolved URI for Verify OTP does NOT contain duplicated /api/v1', () {
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);

    final resolvedUri = apiClient.dio.options.baseUrl.endsWith('/')
        ? '${apiClient.dio.options.baseUrl}${ApiEndpoints.verifyOtp.substring(1)}'
        : '${apiClient.dio.options.baseUrl}${ApiEndpoints.verifyOtp}';

    expect(resolvedUri, equals('http://localhost:5001/api/v1/auth/verify-otp'));
    expect(resolvedUri, isNot(contains('/api/v1/api/v1')));
  });
}
