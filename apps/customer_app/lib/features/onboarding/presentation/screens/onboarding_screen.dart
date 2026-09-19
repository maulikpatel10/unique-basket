import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../widgets/onboarding_page.dart';
import '../widgets/onboarding_pagination.dart';

/// Item data model representing a single onboarding slide.
class OnboardingItem {
  final String imageAssetPath;
  final String title;
  final String subtitle;
  final String buttonText;
  final bool showArrow;

  const OnboardingItem({
    required this.imageAssetPath,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.showArrow = false,
  });
}

/// Full-screen background Onboarding Screen with light theme gradient overlay,
/// prominent logo badge, single top-right Skip button, and theme-matched primary CTA button.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Logo asset displayed in the top header.
  static const String logoAssetPath = 'assets/logos/unique_basket_logo.png';

  /// List of onboarding pages matching the fruits & vegetables brand positioning.
  static const List<OnboardingItem> items = [
    OnboardingItem(
      imageAssetPath: 'assets/images/onboarding_1.png',
      title: 'Freshness\nyou can trust',
      subtitle:
          'Carefully selected fruits and vegetables,\nfresh from the farm to your family.',
      buttonText: 'Next',
      showArrow: true,
    ),
    OnboardingItem(
      imageAssetPath: 'assets/images/onboarding_2.png',
      title: 'Your favorites,\nmade simple',
      subtitle:
          'Find the fruits and vegetables you love,choose what you need, and order in just a few taps.',
      buttonText: 'Next',
      showArrow: true,
    ),
    OnboardingItem(
      imageAssetPath: 'assets/images/onboarding_3.png',
      title: 'From our basket\nto your door',
      subtitle:
          'We bring your fresh produce straight to your doorstep,so you can shop without leaving home.',
      buttonText: 'Get Started',
      showArrow: false,
    ),
  ];

  /// Optional completion callback override (useful for testing).
  final VoidCallback? onComplete;

  const OnboardingScreen({
    super.key,
    this.onComplete,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _handleNext() {
    if (_currentPage < OnboardingScreen.items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    if (!mounted || _hasCompleted) return;
    _hasCompleted = true;

    // Persist onboarding completion
    try {
      ref.read(localStorageProvider).setBool(AppConstants.keyOnboardingCompleted, true);
    } catch (_) {}

    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    try {
      GoRouter.of(context).go(RouteNames.mobileNumber);
    } catch (_) {
      // Safe fallback when running outside GoRouter context
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentItem = OnboardingScreen.items[_currentPage];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // -----------------------------------------------------------------
          // 1. FULL-SCREEN BACKGROUND CAROUSEL WITH LIGHT THEME GRADIENTS
          // -----------------------------------------------------------------
          PageView.builder(
            controller: _pageController,
            itemCount: OnboardingScreen.items.length,
            onPageChanged: _handlePageChanged,
            itemBuilder: (context, index) {
              final item = OnboardingScreen.items[index];
              return OnboardingPage(
                pageIndex: index,
                imageAssetPath: item.imageAssetPath,
                title: item.title,
                subtitle: item.subtitle,
                isCurrentPage: index == _currentPage,
              );
            },
          ),

          // -----------------------------------------------------------------
          // 2. TOP HEADER OVERLAY (Prominent Brand Logo + Single Top-Right Skip)
          // -----------------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: SizedBox(
                  height: 48.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered Brand Logo naturally visible against top gradient
                      Center(
                        child: Image.asset(
                          OnboardingScreen.logoAssetPath,
                          height: context.r(38),
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Single Top-Right Skip Action
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _completeOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            minimumSize: const Size(48.0, 36.0),
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // -----------------------------------------------------------------
          // 3. BOTTOM CONTROLS OVERLAY (Left Dots, Right Primary CTA Button)
          // -----------------------------------------------------------------
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.sm,
                  bottom: AppSpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // A. Left Circular Pagination Dots
                    OnboardingPagination(
                      pageCount: OnboardingScreen.items.length,
                      currentPage: _currentPage,
                    ),

                    // B. Right Pill CTA Button matched to AppColors.primary ("Next →" / "Get Started")
                    SizedBox(
                      height: 44.0,
                      child: ElevatedButton(
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 3,
                          shadowColor: AppColors.primary.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: 10.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentItem.buttonText,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                                color: AppColors.onPrimary,
                              ),
                            ),
                            if (currentItem.showArrow) ...[
                              const SizedBox(width: 6.0),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16.0,
                                color: AppColors.onPrimary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
