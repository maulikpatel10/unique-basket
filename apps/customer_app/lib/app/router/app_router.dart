import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/address/presentation/screens/first_time_add_address_screen.dart';
import '../../features/authentication/presentation/screens/mobile_number_screen.dart';
import '../../features/authentication/presentation/screens/verify_otp_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../../features/legal/presentation/screens/terms_and_conditions_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile_setup/presentation/screens/profile_setup_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
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
