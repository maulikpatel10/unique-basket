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

  // Physical device LAN default (configurable via --dart-define=API_BASE_URL)
  static const String devLanBaseUrl = 'http://192.168.31.243:5001/api/v1';

  // Production
  static const String prodBaseUrl = 'https://api.uniquebasket.com/api/v1';
}
