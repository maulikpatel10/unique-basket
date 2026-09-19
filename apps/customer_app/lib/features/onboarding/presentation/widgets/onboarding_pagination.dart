import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Animated circular pagination indicator for light theme onboarding:
/// - Active: 8dp circular dot (AppColors.primary)
/// - Inactive: 8dp circular dot (Soft light mint / border color)
class OnboardingPagination extends StatelessWidget {
  final int pageCount;
  final int currentPage;

  const OnboardingPagination({
    super.key,
    required this.pageCount,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.primary
                : const Color(0xFFC8DDD6),
          ),
        );
      }),
    );
  }
}
