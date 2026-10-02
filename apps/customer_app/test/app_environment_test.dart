import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:flutter_test/flutter_test.dart';

/// P3-08: build environment selection and base URL rules.
void main() {
  group('resolveEnvironment', () {
    test('defaults to production for release builds and development otherwise', () {
      expect(resolveEnvironment(appEnv: '', isRelease: true), Environment.production);
      expect(resolveEnvironment(appEnv: '', isRelease: false), Environment.development);
    });

    test('APP_ENV overrides the default', () {
      expect(resolveEnvironment(appEnv: 'staging', isRelease: true), Environment.staging);
      expect(resolveEnvironment(appEnv: 'DEVELOPMENT', isRelease: true), Environment.development);
      expect(resolveEnvironment(appEnv: 'production', isRelease: false), Environment.production);
    });
  });

  group('AppConfig.initialize', () {
    test('development falls back to the local emulator/simulator URL', () {
      AppConfig.initialize(environment: Environment.development);
      expect(AppConfig.instance.baseUrl, anyOf(Env.devBaseUrl, Env.devIosBaseUrl));
    });

    test('production without an explicit API base URL fails fast instead of guessing', () {
      expect(() => AppConfig.initialize(environment: Environment.production), throwsStateError);
      expect(() => AppConfig.initialize(environment: Environment.staging), throwsStateError);
    });

    test('production with an explicit base URL uses it', () {
      AppConfig.initialize(environment: Environment.production, customBaseUrl: 'https://api.example.test/api/v1');
      expect(AppConfig.instance.baseUrl, 'https://api.example.test/api/v1');
      expect(AppConfig.instance.isProduction, isTrue);
    });
  });
}
