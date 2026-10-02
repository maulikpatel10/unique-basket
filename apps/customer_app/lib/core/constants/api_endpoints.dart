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

  // Customer / Profile / Favorites / Settings / Serviceability
  static const String profile = '/customer/profile';
  static const String addresses = '/customer/addresses';
  static const String favorites = '/customer/favorites';
  static const String deliverySettings = '/customer/delivery-settings';
  static const String supportedPincodes = '/customer/pincodes';
  static const String serviceabilityCheck = '/customer/serviceability/check';
  static String favoriteProduct(String productId) => '/customer/favorites/$productId';

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
  static String orderById(String id) => '/orders/$id';
  // Notifications
  static const String notifications = '/notifications';
  static const String notificationUnreadCount = '/notifications/unread-count';
  static const String notificationReadAll = '/notifications/read-all';
  static String notificationMarkRead(String id) => '/notifications/$id/read';
}

