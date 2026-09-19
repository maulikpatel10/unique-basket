import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Screen 35 — Terms & Conditions for Unique Basket Customer App.
///
/// Accurately reproduces the approved 35_Terms_And_Conditions design reference:
/// - Dark green top app bar with back navigation and title
/// - Light green header icon badge with globe icon
/// - Bold headline "Terms & Conditions"
/// - Intro description explaining service terms
/// - 10 numbered sections covering online ordering, delivery, produce availability, etc.
/// - Footer note with "Last updated" and copyright notice
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const List<_LegalSection> _sections = [
    _LegalSection(
      title: '1. About UNIQUE BASKET',
      content:
          'UNIQUE BASKET provides an online platform for customers to browse and order fresh fruits and vegetables for delivery within supported service areas.',
    ),
    _LegalSection(
      title: '2. Using Our Service',
      content:
          'Customers can use the UNIQUE BASKET app to browse available fresh produce, manage delivery addresses, place orders, and use the payment methods supported by the service.',
    ),
    _LegalSection(
      title: '3. Account & Mobile Number',
      content:
          'Customers access their account using their mobile number and verification code. Customers are responsible for providing accurate information when using the service.',
    ),
    _LegalSection(
      title: '4. Products & Pricing',
      content:
          'Product availability, quantity, and prices may change based on current availability. The applicable price shown at checkout will apply to the order.',
    ),
    _LegalSection(
      title: '5. Delivery',
      content:
          'Delivery is available only within UNIQUE BASKET\'s supported service areas. Customers must provide an accurate delivery address when placing an order.',
    ),
    _LegalSection(
      title: '6. Orders',
      content:
          'Orders are subject to product availability and successful order processing. UNIQUE BASKET may be unable to fulfill an order when a selected product is unavailable.',
    ),
    _LegalSection(
      title: '7. Payments',
      content:
          'Customers may use the payment methods currently supported by UNIQUE BASKET. Cash on Delivery may be available for eligible orders.',
    ),
    _LegalSection(
      title: '8. Cancellation & Refunds',
      content:
          'Cancellation and refund eligibility depends on the order status and applicable UNIQUE BASKET policies.',
    ),
    _LegalSection(
      title: '9. Changes to These Terms',
      content:
          'UNIQUE BASKET may update these terms from time to time. Updated terms will be made available through the app.',
    ),
    _LegalSection(
      title: '10. Contact',
      content:
          'For questions about these terms or the UNIQUE BASKET service, please use the support options provided by UNIQUE BASKET.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxContentWidth = math.min(context.screenWidth - (AppSpacing.lg * 2), AppBreakpoints.maxLegalWidth);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          key: const Key('terms_back_button'),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22.0,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              try {
                GoRouter.of(context).go(RouteNames.mobileNumber);
              } catch (_) {}
            }
          },
        ),
        title: Text(
          'Terms & Conditions',
          style: AppTextStyles.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18.0,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Center(
            child: SizedBox(
              width: maxContentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Icon badge + Title in one line
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42.0,
                        height: 42.0,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceContainerDark
                              : const Color(0xFFE8F8F5),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Icon(
                          Icons.public_rounded,
                          color: AppColors.primary,
                          size: 22.0,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Terms & Conditions',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Intro Description
                  Text(
                    'Welcome to UNIQUE BASKET. These terms explain the conditions for using our fresh fruits and vegetables ordering service.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Divider
                  Divider(
                    color: isDark
                        ? AppColors.cardBorderDark
                        : const Color(0xFFE2E8F0),
                    thickness: 1.0,
                    height: 32.0,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Numbered Sections
                  ..._sections.map(
                    (sec) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sec.title,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.0,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            sec.content,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Divider
                  Divider(
                    color: isDark
                        ? AppColors.cardBorderDark
                        : const Color(0xFFE2E8F0),
                    thickness: 1.0,
                    height: 24.0,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Footer Notes
                  Text(
                    'Last updated: [To be updated]\n© UNIQUE BASKET. All rights reserved.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark.withValues(alpha: 0.7)
                          : const Color(0xFF94A3B8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  final String title;
  final String content;

  const _LegalSection({required this.title, required this.content});
}
