import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/config/environment.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/local_storage_service.dart';
import 'core/storage/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize App Configuration (Development default; configurable via env/arguments)
  AppConfig.initialize(
    appName: 'Unique Basket',
    environment: Environment.development,
  );

  // Initialize Local SharedPreferences Storage
  final localStorage = await LocalStorageService.create();
  final secureStorage = SecureStorageService();

  if (AppConfig.instance.isDevelopment) {
    await secureStorage.saveTokens(
      accessToken:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjE2Y2QzZmJjLTJjZGEtNDYyYS1hMzMwLWVkY2FkNjkwOGVmMCIsInJvbGUiOiJjdXN0b21lciIsInBob25lIjoiKzkxOTg3NjIxMzg0OSIsImlhdCI6MTc4OTgwMjA1OSwiZXhwIjoxODIxMzM4MDU5fQ.5TNRrjyYK-UKRWwFXt3b0EKlAWH-Tz_w7uokr-BsynQ',
    );
    await localStorage.setBool(AppConstants.keyOnboardingCompleted, true);
    await localStorage.setBool(AppConstants.keyProfileCompleted, true);
    await localStorage.setBool(AppConstants.keyAddressCompleted, true);
  }

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
