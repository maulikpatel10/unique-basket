import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/config/environment.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/local_storage_service.dart';
import 'core/storage/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Environment from --dart-define=APP_ENV (release builds default to production, P3-08).
  // Staging/production require --dart-define=API_BASE_URL.
  AppConfig.initialize(
    appName: 'Unique Basket',
    environment: resolveEnvironment(isRelease: kReleaseMode),
  );

  // Initialize Local SharedPreferences Storage
  final localStorage = await LocalStorageService.create();
  final secureStorage = SecureStorageService();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        secureStorageProvider.overrideWithValue(secureStorage),
      ],
      child: const CustomerApp(),
    ),
  );
}
