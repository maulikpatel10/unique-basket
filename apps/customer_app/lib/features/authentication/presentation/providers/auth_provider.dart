import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Provider for AuthRemoteDataSource.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
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
  return AuthNotifier(
    repository: repository,
    secureStorage: secureStorage,
  );
});

/// StateNotifier responsible for managing authentication flow, OTP sending,
/// OTP verification, token persistence, and error handling.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorageService _secureStorage;

  AuthNotifier({
    required AuthRepository repository,
    required SecureStorageService secureStorage,
  })  : _repository = repository,
        _secureStorage = secureStorage,
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

      state = state.copyWith(
        status: AuthStatus.verified,
        isNewUser: isNewUser,
        userData: userData,
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
        errorMessage: 'Invalid verification code. Please try again.',
      );
      return false;
    }
  }

  /// Logs out the user by clearing secure tokens and resetting state.
  Future<void> logout() async {
    await _secureStorage.clearTokens();
    state = const AuthState();
  }
}
