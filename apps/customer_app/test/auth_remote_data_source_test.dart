import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/core/constants/api_endpoints.dart';
import 'package:customer_app/core/network/api_client.dart';
import 'package:customer_app/features/authentication/data/datasources/auth_remote_data_source.dart';

class MockApiClient extends Fake implements ApiClient {
  String? lastPostPath;
  dynamic lastPostData;
  dynamic mockResponse;

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return mockResponse ?? {'success': true};
  }
}

void main() {
  group('AuthRemoteDataSourceImpl Path Verification', () {
    late MockApiClient mockApiClient;
    late AuthRemoteDataSource dataSource;

    setUp(() {
      mockApiClient = MockApiClient();
      dataSource = AuthRemoteDataSourceImpl(mockApiClient);
    });

    test('sendOtp calls correct endpoint without duplicated /api/v1', () async {
      await dataSource.sendOtp('+919876543210');

      expect(mockApiClient.lastPostPath, equals(ApiEndpoints.sendOtp));
      expect(mockApiClient.lastPostPath, equals('/auth/send-otp'));
      expect(mockApiClient.lastPostPath, isNot(contains('/api/v1')));
      expect(mockApiClient.lastPostData, equals({'phone': '+919876543210'}));
    });

    test('verifyOtp calls correct endpoint without duplicated /api/v1', () async {
      mockApiClient.mockResponse = {
        'success': true,
        'data': {
          'token': 'mock_token',
          'isNewUser': false,
        },
      };

      final result = await dataSource.verifyOtp('+919876543210', '1234');

      expect(mockApiClient.lastPostPath, equals(ApiEndpoints.verifyOtp));
      expect(mockApiClient.lastPostPath, equals('/auth/verify-otp'));
      expect(mockApiClient.lastPostPath, isNot(contains('/api/v1')));
      expect(mockApiClient.lastPostData, equals({
        'phone': '+919876543210',
        'otp': '1234',
      }));
      expect(result['success'], isTrue);
    });
  });
}
