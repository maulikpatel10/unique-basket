import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/address/presentation/screens/first_time_add_address_screen.dart';
import '../../features/authentication/presentation/screens/mobile_number_screen.dart';
import '../../features/authentication/presentation/screens/verify_otp_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/explore/presentation/screens/category_product_listing_screen.dart';
import '../../features/explore/presentation/screens/explore_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../../features/legal/presentation/screens/terms_and_conditions_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/product/presentation/screens/product_details_screen.dart';
import '../../features/profile_setup/presentation/screens/profile_setup_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/orders/presentation/screens/order_success_screen.dart';
import '../../features/orders/presentation/screens/order_tracking_screen.dart';
import '../../features/orders/presentation/screens/order_details_screen.dart';
import '../../features/orders/presentation/screens/my_orders_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/address/presentation/screens/my_addresses_screen.dart';
import '../../features/address/presentation/screens/add_new_address_screen.dart';
import '../../features/address/presentation/screens/edit_address_screen.dart';
import '../../features/payment/presentation/screens/payment_methods_screen.dart';
import '../../features/profile/presentation/screens/help_support_screen.dart';
import '../../features/home/data/models/product_model.dart';


import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.mobileNumber,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final phone = extra?['phone'] as String?;
          return MobileNumberScreen(initialPhoneNumber: phone);
        },
      ),
      GoRoute(
        path: RouteNames.verifyOtp,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final phone = extra?['phone'] as String?;
          return VerifyOtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: RouteNames.profileSetup,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final phone = extra?['phone'] as String?;
          return ProfileSetupScreen(phoneNumber: phone);
        },
      ),
      // Development-only testing route to inspect Screen 06 directly
      GoRoute(
        path: RouteNames.devProfileSetup,
        builder: (context, state) => const ProfileSetupScreen(
          phoneNumber: '+91 98765 43210',
        ),
      ),
      GoRoute(
        path: RouteNames.firstTimeAddAddress,
        builder: (context, state) => const FirstTimeAddAddressScreen(),
      ),
      // Development-only testing route to inspect Screen 07 directly
      GoRoute(
        path: RouteNames.devFirstTimeAddAddress,
        builder: (context, state) => const FirstTimeAddAddressScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.explore,
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: RouteNames.categoryProducts,
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'] ??
              (state.extra as Map<String, dynamic>?)?['categoryId'] as String? ??
              '';
          final categoryName = state.uri.queryParameters['categoryName'] ??
              (state.extra as Map<String, dynamic>?)?['categoryName'] as String? ??
              '';
          return CategoryProductListingScreen(
            categoryId: categoryId,
            categoryName: categoryName,
          );
        },
      ),
      GoRoute(
        path: RouteNames.productDetails,
        builder: (context, state) {
          final productId = state.uri.queryParameters['productId'] ??
              (state.extra as Map<String, dynamic>?)?['productId'] as String? ??
              (state.extra is ProductModel ? (state.extra as ProductModel).id : '');
          final initialProduct = state.extra is ProductModel
              ? state.extra as ProductModel
              : (state.extra as Map<String, dynamic>?)?['product'] as ProductModel?;
          return ProductDetailsScreen(
            productId: productId,
            initialProduct: initialProduct,
          );
        },
      ),
      GoRoute(
        path: RouteNames.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: RouteNames.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: RouteNames.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: RouteNames.search,
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ??
              (state.extra is String ? state.extra as String : null);
          return SearchScreen(initialQuery: query);
        },
      ),
      GoRoute(
        path: RouteNames.orderSuccess,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OrderSuccessScreen(
            orderData: extra,
            orderId: extra?['orderId'] as String?,
          );
        },
      ),
      GoRoute(
        path: RouteNames.orderTracking,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final orderId = extra?['orderId'] as String? ??
              state.uri.queryParameters['orderId'];
          final orderNumber = extra?['orderNumber'] as String? ??
              state.uri.queryParameters['orderNumber'];
          return OrderTrackingScreen(
            orderId: orderId,
            orderNumber: orderNumber,
            initialOrderData: extra,
          );
        },
      ),
      GoRoute(
        path: RouteNames.orderDetails,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final orderId = extra?['orderId'] as String? ??
              state.uri.queryParameters['orderId'];
          final orderNumber = extra?['orderNumber'] as String? ??
              state.uri.queryParameters['orderNumber'];
          return OrderDetailsScreen(
            orderId: orderId,
            orderNumber: orderNumber,
            initialOrderData: extra,
          );
        },
      ),
      GoRoute(
        path: RouteNames.myOrders,
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.myAddresses,
        builder: (context, state) => const MyAddressesScreen(),
      ),
      GoRoute(
        path: RouteNames.addNewAddress,
        builder: (context, state) => const AddNewAddressScreen(),
      ),
      GoRoute(
        path: RouteNames.editAddress,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final addressId = extra?['addressId'] as String? ?? state.uri.queryParameters['addressId'] ?? '';
          return EditAddressScreen(addressId: addressId);
        },
      ),
      GoRoute(
        path: RouteNames.paymentMethods,
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: RouteNames.helpSupport,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: RouteNames.termsAndConditions,
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),


      GoRoute(
        path: RouteNames.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: RouteNames.placeholder,
        builder: (context, state) => const _InitialFoundationScreen(),
      ),
    ],
  );
});

class _InitialFoundationScreen extends StatelessWidget {
  const _InitialFoundationScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_basket_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'UNIQUE BASKET',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Customer Application',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

