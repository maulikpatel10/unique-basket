import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/startup_state_resolver.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../address/data/repositories/customer_address_repository.dart';
import '../../../address/presentation/providers/customer_address_provider.dart';
import '../../../checkout/presentation/providers/order_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../payment/presentation/providers/payment_methods_provider.dart';
import '../../../profile_setup/data/repositories/customer_profile_repository.dart';
import '../../../profile_setup/presentation/providers/customer_profile_provider.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/session_revocation_remote_data_source.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Provider for AuthRemoteDataSource.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});

/// Provider for server-side session revocation on logout.
final sessionRevocationDataSourceProvider = Provider<SessionRevocationRemoteDataSource>((ref) {
  return SessionRevocationRemoteDataSource(ref.watch(apiClientProvider));
});

/// Provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource);
});

/// StateNotifierProvider for authentication state management.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final profileRepository = ref.watch(customerProfileRepositoryProvider);
  final addressRepository = ref.watch(customerAddressRepositoryProvider);
  final localStorage = ref.watch(localStorageProvider);
  return AuthNotifier(
    repository: repository,
    secureStorage: secureStorage,
    profileRepository: profileRepository,
    addressRepository: addressRepository,
    localStorage: localStorage,
    ref: ref,
  );
});

/// StateNotifier responsible for managing authentication flow, OTP sending,
/// OTP verification, token persistence, error handling, and session teardown.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorageService _secureStorage;
  final CustomerProfileRepository? _profileRepository;
  final CustomerAddressRepository? _addressRepository;
  final LocalStorageService? _localStorage;
  final Ref? _ref;

  AuthNotifier({
    required AuthRepository repository,
    required SecureStorageService secureStorage,
    CustomerProfileRepository? profileRepository,
    CustomerAddressRepository? addressRepository,
    LocalStorageService? localStorage,
    Ref? ref,
  })  : _repository = repository,
        _secureStorage = secureStorage,
        _profileRepository = profileRepository,
        _addressRepository = addressRepository,
        _localStorage = localStorage,
        _ref = ref,
        super(const AuthState());

  /// Clears any active error message in the authentication state.
  void clearError() {
    if (state.errorMessage != null || state.status == AuthStatus.error) {
      state = state.copyWith(
        status: state.status == AuthStatus.error ? AuthStatus.initial : state.status,
        errorMessage: null,
      );
    }
  }

  /// Sets or updates the active phone number in state.
  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  /// Initiates OTP request for the provided phone number.
  Future<bool> requestOtp(String phone) async {
    final normalizedPhone = phone.startsWith('+91') ? phone : '+91$phone';
    state = state.copyWith(
      status: AuthStatus.loading,
      phoneNumber: normalizedPhone,
      errorMessage: null,
    );

    try {
      await _repository.sendOtp(normalizedPhone);
      state = state.copyWith(
        status: AuthStatus.otpSent,
        phoneNumber: normalizedPhone,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to send OTP. Please try again.',
      );
      return false;
    }
  }

  /// Resends OTP for the provided phone number.
  Future<bool> resendOtp(String phone) async {
    final normalizedPhone = phone.startsWith('+91') ? phone : '+91$phone';
    state = state.copyWith(
      status: AuthStatus.loading,
      phoneNumber: normalizedPhone,
      errorMessage: null,
    );

    try {
      await _repository.sendOtp(normalizedPhone);
      state = state.copyWith(
        status: AuthStatus.otpSent,
        phoneNumber: normalizedPhone,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to resend OTP. Please try again.',
      );
      return false;
    }
  }

  /// Verifies the OTP with backend service.
  /// On successful verification, securely stores auth tokens and marks user as verified.
  Future<bool> verifyOtp(String phone, String otp) async {
    final normalizedPhone = phone.startsWith('+91') ? phone : '+91$phone';
    state = state.copyWith(
      status: AuthStatus.verifying,
      phoneNumber: normalizedPhone,
      errorMessage: null,
    );

    try {
      final result = await _repository.verifyOtp(normalizedPhone, otp);

      Map<String, dynamic> data = result;
      if (result.containsKey('data') && result['data'] is Map<String, dynamic>) {
        data = result['data'] as Map<String, dynamic>;
      }

      // Clean stale user session cache and in-memory providers before hydrating the new session
      if (_localStorage != null) {
        await _localStorage!.clearUserSessionData();
      }
      _resetUserScopedProviders();

      final token = (data['token'] ?? data['accessToken']) as String?;
      final refreshToken = data['refreshToken'] as String?;

      if (token != null && token.isNotEmpty) {
        await _secureStorage.saveTokens(
          accessToken: token,
          refreshToken: refreshToken,
        );
      }

      final isNewUser = (data['isNewUser'] as bool?) ?? false;
      final userData = data['user'] as Map<String, dynamic>? ?? data;

      StartupDestination destination = StartupDestination.profileSetup;

      if (isNewUser) {
        destination = StartupDestination.profileSetup;
      } else {
        // Query backend for existing customer profile and saved addresses
        Map<String, dynamic>? userProfile;
        if (_profileRepository != null) {
          try {
            final profileRes = await _profileRepository!.getProfile();
            if (profileRes.containsKey('data') && profileRes['data'] is Map<String, dynamic>) {
              final data = profileRes['data'] as Map<String, dynamic>;
              userProfile = data['user'] as Map<String, dynamic>? ?? data;
            } else if (profileRes.containsKey('user') && profileRes['user'] is Map<String, dynamic>) {
              userProfile = profileRes['user'] as Map<String, dynamic>;
            } else {
              userProfile = profileRes;
            }
          } on AppException catch (e) {
            state = state.copyWith(
              status: AuthStatus.error,
              errorMessage: e.message,
            );
            return false;
          } catch (e) {
            state = state.copyWith(
              status: AuthStatus.error,
              errorMessage: 'Failed to retrieve profile details. Please try again.',
            );
            return false;
          }
        }

        List<dynamic>? addresses;
        if (_addressRepository != null) {
          try {
            final addressRes = await _addressRepository!.getAddresses();
            if (addressRes.containsKey('data') && addressRes['data'] is Map<String, dynamic>) {
              final data = addressRes['data'] as Map<String, dynamic>;
              addresses = data['addresses'] as List<dynamic>?;
            } else if (addressRes.containsKey('addresses') && addressRes['addresses'] is List) {
              addresses = addressRes['addresses'] as List<dynamic>;
            }
          } on AppException catch (e) {
            state = state.copyWith(
              status: AuthStatus.error,
              errorMessage: e.message,
            );
            return false;
          } catch (e) {
            state = state.copyWith(
              status: AuthStatus.error,
              errorMessage: 'Failed to retrieve saved addresses. Please try again.',
            );
            return false;
          }
        }

        final profileName = userProfile?['name'] as String? ?? userData['name'] as String?;
        final isProfileComplete = profileName != null && profileName.trim().isNotEmpty;

        if (!isProfileComplete) {
          destination = StartupDestination.profileSetup;
        } else {
          // Cache profile details locally if available
          if (_localStorage != null && userProfile != null) {
            try {
              await _localStorage!.setJson(AppConstants.keyUserData, userProfile);
              await _localStorage!.setBool(AppConstants.keyProfileCompleted, true);
              if (userProfile['dob'] != null) {
                await _localStorage!.setString(AppConstants.keyUserDob, userProfile['dob'].toString());
              }
            } catch (_) {}
          }

          final hasAddresses = addresses != null && addresses.isNotEmpty;
          if (!hasAddresses) {
            destination = StartupDestination.addressSetup;
          } else {
            // Cache address details locally if available
            if (_localStorage != null && addresses.first is Map<String, dynamic>) {
              try {
                await _localStorage!.setJson(AppConstants.keyUserAddress, addresses.first as Map<String, dynamic>);
                await _localStorage!.setBool(AppConstants.keyAddressCompleted, true);
              } catch (_) {}
            }
            destination = StartupDestination.home;
          }
        }
      }

      // Hydrate user cart and favorites for the authenticated session
      if (kDebugMode) {
        debugPrint('[UB-PERSISTENCE] AUTH VERIFY SUCCESS -> Loading Cart & Favorites');
      }
      _ref?.read(cartNotifierProvider.notifier).loadCart();
      _ref?.read(favoritesNotifierProvider.notifier).loadFavorites();

      state = state.copyWith(
        status: AuthStatus.verified,
        isNewUser: isNewUser,
        userData: userData,
        phoneNumber: normalizedPhone,
        resolvedDestination: destination,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid verification code. Please try again.',
      );
      return false;
    }
  }

  /// Invalidates and resets all Riverpod providers that contain authenticated user data.
  void _resetUserScopedProviders() {
    if (_ref == null) return;
    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] USER SCOPED PROVIDERS RESET');
    }
    try {
      _ref!.invalidate(customerProfileProvider);
      _ref!.invalidate(customerAddressesProvider);
      _ref!.invalidate(customerOrdersProvider);
      _ref!.invalidate(paymentMethodsProvider);
      _ref!.invalidate(servingStoreProvider);
      _ref!.invalidate(nearbyStoresProvider);
      _ref!.invalidate(homeProductsProvider);
      _ref!.invalidate(categoryProductsProvider);

      _ref!.read(cartNotifierProvider.notifier).clearCart();
      _ref!.read(favoritesNotifierProvider.notifier).clearFavorites();
      _ref!.read(recentSearchesProvider.notifier).clearAll();
      _ref!.read(notificationNotifierProvider.notifier).reset();
    } catch (_) {}
  }

  /// Best-effort revocation of the refresh session on the backend.
  /// Never blocks local logout: failures (offline, missing provider) are ignored.
  Future<void> _revokeServerSession() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.trim().isEmpty || _ref == null) return;
      final revocation = _ref!.read(sessionRevocationDataSourceProvider);
      // Fire-and-forget: local logout never waits for (or fails because of) the network.
      unawaited(revocation.revokeSession(refreshToken).catchError((Object _) {}));
    } catch (_) {
      // Local logout proceeds regardless.
    }
  }

  /// Logs out the user by clearing secure tokens, purging user-scoped local storage,
  /// resetting user-bound Riverpod providers, and clearing authentication state.
  Future<void> logout() async {
    if (kDebugMode) {
      debugPrint('[UB-PERSISTENCE] LOGOUT CLEANUP');
    }
    await _revokeServerSession();
    await _secureStorage.clearTokens();
    if (_localStorage != null) {
      await _localStorage!.clearUserSessionData();
    }
    _resetUserScopedProviders();
    state = const AuthState();
  }
}
