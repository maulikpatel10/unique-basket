import 'package:flutter/foundation.dart';

import '../../app/router/route_names.dart';
import '../../features/authentication/data/repositories/auth_repository.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';
import '../utils/jwt_utils.dart';

/// Represents the startup destination of the application based on
/// persistent state.
enum StartupDestination {
  onboarding,
  mobileAuthentication,
  profileSetup,
  addressSetup,
  home,
}

extension StartupDestinationExtension on StartupDestination {
  String get routeName {
    switch (this) {
      case StartupDestination.onboarding:
        return RouteNames.onboarding;

      case StartupDestination.mobileAuthentication:
        return RouteNames.mobileNumber;

      case StartupDestination.profileSetup:
        return RouteNames.profileSetup;

      case StartupDestination.addressSetup:
        return RouteNames.firstTimeAddAddress;

      case StartupDestination.home:
        return RouteNames.home;
    }
  }
}

/// Service that inspects persistent storage and session state to resolve
/// the correct startup destination for new, returning, or incomplete users.
class StartupStateResolver {
  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;
  final AuthRepository _authRepository;

  StartupStateResolver({
    required LocalStorageService localStorage,
    required SecureStorageService secureStorage,
    required AuthRepository authRepository,
  })  : _localStorage = localStorage,
        _secureStorage = secureStorage,
        _authRepository = authRepository;

  Future<StartupDestination> resolve() async {
    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] STARTUP STATE RESOLVER: START');
    }

    // -----------------------------------------------------------------------
    // 1. Brand-new user: Check if onboarding has been completed
    // -----------------------------------------------------------------------
    final bool onboardingCompleted =
        _localStorage.getBool(AppConstants.keyOnboardingCompleted) ?? false;

    if (!onboardingCompleted) {
      if (kDebugMode) {
        debugPrint(
          '[UB-PERSISTENCE] RESOLVED DESTINATION -> onboarding',
        );
      }

      return StartupDestination.onboarding;
    }

    // -----------------------------------------------------------------------
    // 2. Onboarding completed: Check if access token exists
    // -----------------------------------------------------------------------
    final String? accessToken = await _secureStorage.getAccessToken();

    final bool hasToken =
        accessToken != null && accessToken.trim().isNotEmpty;

    if (kDebugMode) {
      debugPrint(
        '[UB-PERSISTENCE] AUTH TOKEN EXISTS: $hasToken',
      );
    }

    if (!hasToken) {
      if (kDebugMode) {
        debugPrint(
          '[UB-PERSISTENCE] RESOLVED DESTINATION -> '
          'mobileAuthentication (no token)',
        );
      }

      return StartupDestination.mobileAuthentication;
    }

    // -----------------------------------------------------------------------
    // 3. Check access token expiration
    // -----------------------------------------------------------------------
    final bool isExpired = JwtUtils.isExpired(accessToken);

    if (kDebugMode) {
      debugPrint(
        '[UB-PERSISTENCE] AUTH TOKEN IS EXPIRED: $isExpired',
      );
    }

    if (isExpired) {
      final String? refreshToken = await _secureStorage.getRefreshToken();

      // ---------------------------------------------------------------------
      // No refresh token -> session cannot be restored
      // ---------------------------------------------------------------------
      if (refreshToken == null || refreshToken.trim().isEmpty) {
        await _secureStorage.clearTokens();
        await _localStorage.clearUserSessionData();

        if (kDebugMode) {
          debugPrint(
            '[UB-PERSISTENCE] RESOLVED DESTINATION -> '
            'mobileAuthentication (refresh token missing)',
          );
        }

        return StartupDestination.mobileAuthentication;
      }

      try {
        // -------------------------------------------------------------------
        // Attempt to refresh the expired access token
        // -------------------------------------------------------------------
        final String? newAccessToken =
            await _authRepository.refreshToken(refreshToken);

        // -------------------------------------------------------------------
        // Backend returned no usable access token.
        //
        // Treat this as an invalid session because the refresh operation
        // completed but did not provide a token.
        // -------------------------------------------------------------------
        if (newAccessToken == null || newAccessToken.trim().isEmpty) {
          await _secureStorage.clearTokens();
          await _localStorage.clearUserSessionData();

          if (kDebugMode) {
            debugPrint(
              '[UB-PERSISTENCE] RESOLVED DESTINATION -> '
              'mobileAuthentication '
              '(refresh returned no token)',
            );
          }

          return StartupDestination.mobileAuthentication;
        }

        // -------------------------------------------------------------------
        // Save the newly issued access token while preserving the existing
        // refresh token.
        // -------------------------------------------------------------------
        await _secureStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: refreshToken,
        );

        if (kDebugMode) {
          debugPrint(
            '[UB-PERSISTENCE] ACCESS TOKEN REFRESHED SUCCESSFULLY',
          );
        }
      } on UnauthorizedException {
        // -------------------------------------------------------------------
        // The backend explicitly rejected the refresh token.
        //
        // This means the session is no longer valid, so it is safe to clear
        // the stored authentication/session state.
        // -------------------------------------------------------------------
        await _secureStorage.clearTokens();
        await _localStorage.clearUserSessionData();

        if (kDebugMode) {
          debugPrint(
            '[UB-PERSISTENCE] RESOLVED DESTINATION -> '
            'mobileAuthentication '
            '(refresh token unauthorized)',
          );
        }

        return StartupDestination.mobileAuthentication;
      } catch (error) {
        // -------------------------------------------------------------------
        // IMPORTANT:
        //
        // Do NOT clear credentials for:
        // - Network errors
        // - Timeout errors
        // - Server errors (5xx)
        // - Unexpected temporary errors
        //
        // The refresh token may still be valid. Destroying it here would
        // unnecessarily log the user out because of a temporary problem.
        //
        // We keep the existing credentials and continue resolving the
        // persisted user state.
        // -------------------------------------------------------------------
        if (kDebugMode) {
          debugPrint(
            '[UB-PERSISTENCE] TOKEN REFRESH TEMPORARILY FAILED: $error',
          );

          debugPrint(
            '[UB-PERSISTENCE] KEEPING EXISTING SESSION CREDENTIALS',
          );
        }
      }
    }

    // -----------------------------------------------------------------------
    // 4. Authenticated user: Check if profile setup is completed
    // -----------------------------------------------------------------------
    final bool profileCompleted =
        _localStorage.getBool(AppConstants.keyProfileCompleted) ?? false;

    if (!profileCompleted) {
      if (kDebugMode) {
        debugPrint(
          '[UB-PERSISTENCE] RESOLVED DESTINATION -> profileSetup',
        );
      }

      return StartupDestination.profileSetup;
    }

    // -----------------------------------------------------------------------
    // 5. Profile completed: Check if address setup is completed
    // -----------------------------------------------------------------------
    final bool addressCompleted =
        _localStorage.getBool(AppConstants.keyAddressCompleted) ?? false;

    if (!addressCompleted) {
      if (kDebugMode) {
        debugPrint(
          '[UB-PERSISTENCE] RESOLVED DESTINATION -> addressSetup',
        );
      }

      return StartupDestination.addressSetup;
    }

    // -----------------------------------------------------------------------
    // 6. Fully completed returning user
    // -----------------------------------------------------------------------
    if (kDebugMode) {
      debugPrint(
        '[UB-PERSISTENCE] RESOLVED DESTINATION -> '
        'home (authenticated session ready)',
      );
    }

    return StartupDestination.home;
  }
}