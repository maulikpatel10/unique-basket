import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../network/api_client.dart';
import '../services/startup_state_resolver.dart';
import '../session/session_expiry_notifier.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';

/// Provider for Local SharedPreferences Storage Service.
/// Overridden at runtime in main() after initialization.
final localStorageProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('localStorageProvider must be overridden in ProviderScope');
});

/// Provider for Secure Storage Service (Encrypted Keystore / Keychain).
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Notifies the router when the session expires involuntarily (refresh rejected).
final sessionExpiryNotifierProvider = Provider<SessionExpiryNotifier>((ref) {
  final notifier = SessionExpiryNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Provider for the centralized ApiClient.
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final localStorage = ref.watch(localStorageProvider);
  final sessionExpiry = ref.watch(sessionExpiryNotifierProvider);
  return ApiClient(
    secureStorage: secureStorage,
    localStorage: localStorage,
    onSessionExpired: sessionExpiry.notifySessionExpired,
  );
});

/// Provider for the StartupStateResolver.
final startupStateResolverProvider = Provider<StartupStateResolver>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return StartupStateResolver(
    localStorage: localStorage,
    secureStorage: secureStorage,
    authRepository: authRepository,
  );
});
