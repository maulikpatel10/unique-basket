import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

enum ButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonVariant variant;
  final IconData? icon;
  final Widget? prefix;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.prefix,
    this.height = AppDimensions.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    BorderSide? borderSide;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = AppColors.primary;
        textColor = AppColors.onPrimary;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppColors.secondary;
        textColor = AppColors.onSecondary;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        borderSide = const BorderSide(
          color: AppColors.primary,
          width: AppDimensions.focusedBorderWidth,
        );
        break;
      case ButtonVariant.danger:
        backgroundColor = AppColors.error;
        textColor = AppColors.onError;
        borderSide = BorderSide.none;
        break;
    }

    final isEnabled = onPressed != null && !isLoading;

    final buttonWidget = SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? backgroundColor : AppColors.cardBorder,
          foregroundColor: isEnabled ? textColor : AppColors.textMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.rMd,
            side: isEnabled ? borderSide : BorderSide.none,
          ),
          padding: AppSpacing.buttonPadding,
        ),
        child: isLoading
            ? SizedBox(
                height: AppDimensions.iconMd,
                width: AppDimensions.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefix != null) ...[
                    prefix!,
                    const SizedBox(width: AppSpacing.sm),
                  ] else if (icon != null) ...[
                    Icon(icon, size: AppDimensions.iconMd, color: textColor),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.button.copyWith(
                      color: isEnabled ? textColor : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
      ),
    );

    return buttonWidget;
  }
}
