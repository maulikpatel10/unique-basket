import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/config/environment.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize App Configuration (Development default; configurable via env/arguments)
  AppConfig.initialize(
    appName: 'Unique Basket',
    environment: Environment.development,
  );

  // Initialize Local SharedPreferences Storage
  final localStorage = await LocalStorageService.create();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
      ],
      child: const CustomerApp(),
    ),
  );
}
