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

  /// Explore / Category listing screen (Screen 09).
  static const String explore = '/explore';

  /// Category product listing screen (Screen 10).
  static const String categoryProducts = '/category-products';

  /// Product details screen (Screen 11).
  static const String productDetails = '/product-details';

  /// Cart screen (Screen 12 & Screen 13).
  static const String cart = '/cart';

  /// Checkout screen (Screen 16).
  static const String checkout = '/checkout';

  /// Order success confirmation screen (Screen 20).
  static const String orderSuccess = '/orders/success';

  /// Order live tracking screen (Screen 21 placeholder).
  static const String orderTracking = '/orders/track';

  /// Order details screen (Screen 22).
  static const String orderDetails = '/orders/details';

  /// My Orders screen (Screen 27).
  static const String myOrders = '/orders';

  /// Search screen (Screen 17, 18, 19).
  static const String search = '/search';

  /// Favourites / Wishlist screen (Screen 14 & Screen 15).
  static const String favorites = '/favorites';

  /// Notifications screen (Screen 24).
  static const String notifications = '/notifications';

  /// Profile screen (Screen 25).
  static const String profile = '/profile';

  /// Edit Profile screen (Screen 26).
  static const String editProfile = '/profile/edit';

  /// My Addresses screen (Screen 29).
  static const String myAddresses = '/profile/addresses';

  /// Add New Address screen (Screen 30 placeholder navigation contract).
  static const String addNewAddress = '/address/add';

  /// Edit Address screen (Screen 31 placeholder navigation contract).
  static const String editAddress = '/address/edit';

  /// Payment Methods screen (Screen 32).
  static const String paymentMethods = '/profile/payment-methods';

  /// Help & Support screen (Screen 33).
  static const String helpSupport = '/help-support';

  /// Development / testing only route to inspect Screen 07 directly without API calls.
  static const String devFirstTimeAddAddress = '/dev/address-first-time-add';

  /// Terms & Conditions screen (Screen 35).
  static const String termsAndConditions = '/terms-and-conditions';

  /// Privacy Policy screen (Screen 36).
  static const String privacyPolicy = '/privacy-policy';

  /// Bootstrap foundation placeholder screen (post-onboarding target until feature screens are added).
  static const String placeholder = '/placeholder';
}
