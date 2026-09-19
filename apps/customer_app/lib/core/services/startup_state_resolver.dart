import '../../app/router/route_names.dart';
import '../constants/app_constants.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';

/// Represents the startup destination of the application based on persistent state.
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

  StartupStateResolver({
    required LocalStorageService localStorage,
    required SecureStorageService secureStorage,
  })  : _localStorage = localStorage,
        _secureStorage = secureStorage;

  Future<StartupDestination> resolve() async {
    // 1. Brand-new user: Check if onboarding has been completed
    final bool onboardingCompleted =
        _localStorage.getBool(AppConstants.keyOnboardingCompleted) ?? false;
    if (!onboardingCompleted) {
      return StartupDestination.onboarding;
    }

    // 2. Onboarding completed: Check if access token is present in secure storage
    final String? accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      return StartupDestination.mobileAuthentication;
    }

    // 3. Authenticated user: Check if profile setup is completed
    final bool profileCompleted =
        _localStorage.getBool(AppConstants.keyProfileCompleted) ?? false;
    if (!profileCompleted) {
      return StartupDestination.profileSetup;
    }

    // 4. Profile completed: Check if address setup is completed
    final bool addressCompleted =
        _localStorage.getBool(AppConstants.keyAddressCompleted) ?? false;
    if (!addressCompleted) {
      return StartupDestination.addressSetup;
    }

    // 5. Fully completed returning user
    return StartupDestination.home;
  }
}
