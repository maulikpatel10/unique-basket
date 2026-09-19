import 'dart:io';
import 'package:dio/dio.dart';
import '../../app/config/app_config.dart';
import '../errors/app_exception.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio _dio;
  final Dio _tokenDio;
  final SecureStorageService _secureStorage;

  ApiClient({
    required SecureStorageService secureStorage,
    Dio? dio,
    Dio? tokenDio,
  })  : _secureStorage = secureStorage,
        _dio = dio ?? Dio(),
        _tokenDio = tokenDio ?? Dio() {
    final config = AppConfig.instance;

    final baseOptions = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.options = baseOptions;
    _tokenDio.options = baseOptions;

    _dio.interceptors.add(
      AuthInterceptor(
        secureStorage: _secureStorage,
        tokenDio: _tokenDio,
      ),
    );
  }

  Dio get dio => _dio;
  Dio get tokenDio => _tokenDio;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }

  dynamic _handleResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['success'] == false) {
        throw BusinessException(
          message: data['message'] ?? 'An error occurred.',
          errorCode: data['errorCode'],
          statusCode: response.statusCode,
        );
      }
      return data['data'] ?? data;
    }
    return data;
  }

  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.badResponse:
        final response = error.response;
        final statusCode = response?.statusCode;
        final data = response?.data;

        if (statusCode == 401) {
          return const UnauthorizedException();
        }

        String message = 'An unexpected error occurred.';
        String? errorCode;

        if (data is Map<String, dynamic>) {
          message = data['message'] ?? message;
          errorCode = data['errorCode'];
        }

        if (statusCode != null && statusCode >= 500) {
          return ServerException(message: message, statusCode: statusCode);
        }

        return BusinessException(
          message: message,
          errorCode: errorCode,
          statusCode: statusCode,
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const NetworkException();
        }
        return NetworkException(message: error.message ?? 'Network connection failed.');

      case DioExceptionType.cancel:
        return const AppException(message: 'Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const AppException(message: 'Invalid server SSL certificate.');

      default:
        return AppException(message: error.message ?? 'An unexpected network error occurred.');
    }
  }
}
