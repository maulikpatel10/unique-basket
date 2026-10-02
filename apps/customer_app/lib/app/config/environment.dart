enum Environment {
  development,
  staging,
  production,
}

class Env {
  // Android Emulator default (10.0.2.2 maps to host machine)
  static const String devBaseUrl = 'http://10.0.2.2:5001/api/v1';

  // iOS Simulator default (localhost maps to host machine)
  static const String devIosBaseUrl = 'http://localhost:5001/api/v1';

  // Physical devices / staging / production: pass --dart-define=API_BASE_URL=<url>.
  // No production URL is hard-coded: the production domain is not decided yet (P4-13).
}

/// Resolves the build environment from --dart-define=APP_ENV (development|staging|production).
/// Without APP_ENV, release builds are production and debug/profile builds are development.
Environment resolveEnvironment({String appEnv = const String.fromEnvironment('APP_ENV'), required bool isRelease}) {
  switch (appEnv.trim().toLowerCase()) {
    case 'development':
      return Environment.development;
    case 'staging':
      return Environment.staging;
    case 'production':
      return Environment.production;
    default:
      return isRelease ? Environment.production : Environment.development;
  }
}
