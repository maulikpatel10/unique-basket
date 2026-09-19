import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static final Map<String, String> _memoryFallback = {};

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _memoryFallback[AppConstants.keyAccessToken] = accessToken;
    try {
      await _storage.write(key: AppConstants.keyAccessToken, value: accessToken);
    } catch (_) {}
    if (refreshToken != null) {
      _memoryFallback[AppConstants.keyRefreshToken] = refreshToken;
      try {
        await _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
      } catch (_) {}
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: AppConstants.keyAccessToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    return _memoryFallback[AppConstants.keyAccessToken];
  }

  Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: AppConstants.keyRefreshToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    return _memoryFallback[AppConstants.keyRefreshToken];
  }

  Future<void> clearTokens() async {
    _memoryFallback.remove(AppConstants.keyAccessToken);
    _memoryFallback.remove(AppConstants.keyRefreshToken);
    try {
      await _storage.delete(key: AppConstants.keyAccessToken);
      await _storage.delete(key: AppConstants.keyRefreshToken);
    } catch (_) {}
  }

  Future<void> write(String key, String value) async {
    _memoryFallback[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> read(String key) async {
    try {
      final val = await _storage.read(key: key);
      if (val != null) return val;
    } catch (_) {}
    return _memoryFallback[key];
  }

  Future<void> delete(String key) async {
    _memoryFallback.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    _memoryFallback.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
