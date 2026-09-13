import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
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
}
