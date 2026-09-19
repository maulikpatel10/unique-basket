enum AuthStatus { initial, loading, otpSent, verifying, verified, error }

class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final String? errorMessage;
  final bool isNewUser;
  final Map<String, dynamic>? userData;

  const AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.errorMessage,
    this.isNewUser = false,
    this.userData,
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isVerifying => status == AuthStatus.verifying;
  bool get isOtpSent => status == AuthStatus.otpSent;
  bool get isVerified => status == AuthStatus.verified;
  bool get hasError => status == AuthStatus.error && errorMessage != null;

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? errorMessage,
    bool? isNewUser,
    Map<String, dynamic>? userData,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: errorMessage,
      isNewUser: isNewUser ?? this.isNewUser,
      userData: userData ?? this.userData,
    );
  }
}
