import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.titleSmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          maxLines: maxLines,
          autofocus: autofocus,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            contentPadding: AppSpacing.inputPadding,
            border: OutlineInputBorder(
              borderRadius: AppRadius.rMd,
              borderSide: BorderSide(
                color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
                width: AppDimensions.borderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.rMd,
              borderSide: BorderSide(
                color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
                width: AppDimensions.borderWidth,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.rMd,
              borderSide: BorderSide(
                color: AppColors.primary,
                width: AppDimensions.focusedBorderWidth,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.rMd,
              borderSide: BorderSide(
                color: AppColors.error,
                width: AppDimensions.borderWidth,
              ),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.rMd,
              borderSide: BorderSide(
                color: AppColors.error,
                width: AppDimensions.focusedBorderWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
