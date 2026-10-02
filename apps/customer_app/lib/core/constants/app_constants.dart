class AppConstants {
  static const String appName = 'Unique Basket';
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
  static const String currencyLocale = 'en_IN';
  static const String defaultCountryCode = '+91';

  // Storage Keys
  static const String keyAccessToken = 'ub_access_token';
  static const String keyRefreshToken = 'ub_refresh_token';
  static const String keyUserData = 'ub_user_data';
  static const String keyUserDob = 'ub_user_dob';
  static const String keyUserAddress = 'ub_user_address';
  static const String keyCustomerRecentSearches = 'ub_customer_recent_searches';
  static const String keySavedPaymentMethods = 'ub_saved_payment_methods';
  static const String keyUserFavorites = 'ub_user_favorites';
  static const String keyUserCart = 'ub_user_cart';

  // Setup Flow Flags
  static const String keyOnboardingCompleted = 'ub_onboarding_completed';
  static const String keyProfileCompleted = 'ub_profile_completed';
  static const String keyAddressCompleted = 'ub_address_completed';

  /// User-scoped storage keys that MUST be cleared on logout or account switch.
  static const List<String> userScopedStorageKeys = [
    keyUserData,
    keyUserDob,
    keyUserAddress,
    keyProfileCompleted,
    keyAddressCompleted,
    keyCustomerRecentSearches,
    keySavedPaymentMethods,
    keyUserFavorites,
    keyUserCart,
  ];

  /// Device-scoped storage keys that MUST be preserved across logout.
  static const List<String> deviceScopedStorageKeys = [
    keyOnboardingCompleted,
  ];
}
