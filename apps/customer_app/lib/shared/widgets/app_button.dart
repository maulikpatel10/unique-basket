import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
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
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    BorderSide? borderSide;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppColors.secondary;
        textColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case ButtonVariant.danger:
        backgroundColor = AppColors.error;
        textColor = Colors.white;
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
            borderRadius: AppSpacing.roundedMedium,
            side: isEnabled ? borderSide : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22.0,
                width: 22.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefix != null) ...[
                    prefix!,
                    const SizedBox(width: 8.0),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 20.0, color: textColor),
                    const SizedBox(width: 8.0),
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
