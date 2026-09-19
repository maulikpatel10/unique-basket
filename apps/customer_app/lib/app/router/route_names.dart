/// Route path constants for the Unique Basket Customer App.
abstract final class RouteNames {
  /// Splash screen - initial launch destination.
  static const String splash = '/';

  /// Initial route alias for backward compatibility.
  static const String initial = splash;

  /// Onboarding screen - feature discovery walkthrough.
  static const String onboarding = '/onboarding';

  /// Mobile number authentication screen (Screen 04).
  static const String mobileNumber = '/auth/mobile';

  /// Verify mobile OTP screen (Screen 05).
  static const String verifyOtp = '/auth/verify-otp';

  /// Profile setup screen (Screen 06).
  static const String profileSetup = '/profile-setup';

  /// First time add address screen (Screen 07 placeholder target).
  static const String firstTimeAddAddress = '/address/first-time-add';

  /// Development / testing only route to inspect Screen 06 directly without API calls.
  static const String devProfileSetup = '/dev/profile-setup';

  /// Home screen (Screen 08).
  static const String home = '/home';

  /// Development / testing only route to inspect Screen 07 directly without API calls.
  static const String devFirstTimeAddAddress = '/dev/address-first-time-add';

  /// Terms & Conditions screen (Screen 35).
  static const String termsAndConditions = '/terms-and-conditions';

  /// Privacy Policy screen (Screen 36).
  static const String privacyPolicy = '/privacy-policy';

  /// Bootstrap foundation placeholder screen (post-onboarding target until feature screens are added).
  static const String placeholder = '/placeholder';
}
