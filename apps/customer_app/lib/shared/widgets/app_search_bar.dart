import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';

/// Reusable Glass/Translucent Search Bar for Unique Basket.
///
/// Supports:
/// - Tap-to-navigate mode (`readOnly: true`, fires [onTap])
/// - Active text input mode (`readOnly: false`, with [controller], [onChanged], [onSubmitted])
/// - Trailing action (Microphone button with customizable callback [onTrailingTap])
/// - Frosted glass translucent styling with blur and subtle border
/// - Theme-aware light and dark styling
class AppSearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onTrailingTap;
  final Widget? leading;
  final Widget? trailing;
  final IconData leadingIcon;
  final IconData trailingIcon;
  final Key? trailingKey;
  final bool readOnly;
  final bool autofocus;
  final bool enabled;
  final bool isGlass;
  final double height;
  final EdgeInsetsGeometry? margin;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search for fresh fruits, veggies...',
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onTrailingTap,
    this.leading,
    this.trailing,
    this.leadingIcon = Icons.search_rounded,
    this.trailingIcon = Icons.mic_none_rounded,
    this.trailingKey = const Key('home_search_mic_button'),
    this.readOnly = true,
    this.autofocus = false,
    this.enabled = true,
    this.isGlass = true,
    this.height = 46.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.88);

    final borderColor = isDark
        ? AppColors.cardBorderDark.withValues(alpha: 0.6)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.85);

    Widget searchBarContent = Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        children: [
          leading ??
              Icon(
                leadingIcon,
                color: const Color(0xFF014D40),
                size: 22.0,
              ),
          const SizedBox(width: 10.0),
          Expanded(
            child: readOnly
                ? Text(
                    hintText,
                    style: TextStyle(
                      fontSize: context.sp(13.5),
                      color: const Color(0xFF94A3B8),
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    enabled: enabled,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    style: TextStyle(
                      fontSize: context.sp(14),
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        fontSize: context.sp(13.5),
                        color: const Color(0xFF94A3B8),
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
          ),
          trailing ??
              IconButton(
                key: trailingKey,
                onPressed: onTrailingTap ?? onTap,
                icon: Icon(
                  trailingIcon,
                  color: const Color(0xFF0F172A),
                  size: 20.0,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36.0,
                  minHeight: 36.0,
                ),
              ),
        ],
      ),
    );

    if (isGlass) {
      searchBarContent = ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: searchBarContent,
        ),
      );
    }

    if (readOnly) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: searchBarContent,
      );
    }

    return searchBarContent;
  }
}
