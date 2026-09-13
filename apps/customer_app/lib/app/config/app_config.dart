import 'dart:io';
import 'environment.dart';

class AppConfig {
  final String appName;
  final Environment environment;
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  const AppConfig({
    required this.appName,
    required this.environment,
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
  });

  static AppConfig? _instance;

  static AppConfig get instance {
    if (_instance == null) {
      throw StateError('AppConfig must be initialized with AppConfig.initialize() before use.');
    }
    return _instance!;
  }

  static void initialize({
    String appName = 'Unique Basket',
    Environment environment = Environment.development,
    String? customBaseUrl,
  }) {
    // 1. Check if passed via --dart-define=API_BASE_URL
    const dartDefineUrl = String.fromEnvironment('API_BASE_URL');

    String baseUrl;
    if (dartDefineUrl.isNotEmpty) {
      baseUrl = dartDefineUrl;
    } else if (customBaseUrl != null && customBaseUrl.isNotEmpty) {
      baseUrl = customBaseUrl;
    } else {
      switch (environment) {
        case Environment.development:
          // Automatic platform-aware defaults:
          // iOS Simulator connects to host machine via localhost
          // Android Emulator connects to host machine via 10.0.2.2
          try {
            baseUrl = Platform.isIOS ? Env.devIosBaseUrl : Env.devBaseUrl;
          } catch (_) {
            baseUrl = Env.devBaseUrl;
          }
          break;
        case Environment.staging:
        case Environment.production:
          baseUrl = Env.prodBaseUrl;
          break;
      }
    }

    _instance = AppConfig(
      appName: appName,
      environment: environment,
      baseUrl: baseUrl,
    );
  }

  bool get isDevelopment => environment == Environment.development;
  bool get isProduction => environment == Environment.production;
}
