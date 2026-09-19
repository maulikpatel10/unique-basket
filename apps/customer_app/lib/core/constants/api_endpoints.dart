/// API Endpoint Constants for Unique Basket.
///
/// NOTE: The API Base URL already includes the version prefix (e.g., `/api/v1`).
/// All endpoints below are relative to that Base URL and do NOT repeat `/api/v1`.
class ApiEndpoints {
  // Authentication
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Customer / Profile
  static const String profile = '/customer/profile';
  static const String addresses = '/customer/addresses';

  // Stores & Catalog
  static const String stores = '/stores';
  static const String nearbyStores = '/stores/nearby';
  static const String categories = '/categories';
  static const String products = '/products';
  static const String banners = '/banners';
  static String storeProducts(String storeId) => '/products/store/$storeId';

  // Cart & Orders
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String payments = '/payments';
  static const String notifications = '/notifications';
}
