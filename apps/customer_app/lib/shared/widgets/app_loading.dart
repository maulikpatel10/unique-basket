import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

class AppLoading extends StatelessWidget {
  final String? message;
  final bool isOverlay;

  const AppLoading({
    super.key,
    this.message,
    this.isOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (isOverlay) {
      return Container(
        color: isDark ? AppColors.overlayDark : AppColors.overlay,
        child: content,
      );
    }

    return content;
  }
}
