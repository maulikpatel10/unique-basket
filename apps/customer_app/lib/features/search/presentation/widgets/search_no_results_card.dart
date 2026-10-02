import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/widgets.dart';

/// Screen 19 Empty Search Result Card matching 19_Search_No_Results.png.
class SearchNoResultsCard extends StatelessWidget {
  final String query;
  final VoidCallback onSearchAgain;

  const SearchNoResultsCard({
    super.key,
    required this.query,
    required this.onSearchAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: isDark
                  ? AppColors.cardBorderDark
                  : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Concentric Circular Illustration Container
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: context.r(120.0),
                    height: context.r(120.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFEDD5),
                        width: 2.0,
                      ),
                    ),
                  ),
                  Container(
                    width: context.r(86.0),
                    height: context.r(86.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.shopping_basket_outlined,
                            size: context.r(40.0),
                            color: const Color(0xFF014D40),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.all(3.0),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF97316),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 10.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 14.0,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 13.0,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(24.0)),

              // 2. Title
              Text(
                'No products found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.sp(22.0),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF014D40),
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
              const SizedBox(height: 10.0),

              // 3. Subtitle Description
              Text(
                query.isNotEmpty
                    ? 'We couldn\'t find anything matching "$query".'
                    : 'We couldn\'t find any matching products.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.sp(14.5),
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF334155),
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'Try checking the spelling, using broader keywords, or searching for a different fresh item.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.sp(13.0),
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  fontFamily: AppTextStyles.fontFamily,
                  height: 1.4,
                ),
              ),
              SizedBox(height: context.h(28.0)),

              // 4. "Search Again" CTA Button
              AppButton(
                label: 'Search Again',
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
                icon: Icons.search_rounded,
                iconPosition: IconPosition.leading,
                onPressed: onSearchAgain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
