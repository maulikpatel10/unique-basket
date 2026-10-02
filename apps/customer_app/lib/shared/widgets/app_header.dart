import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';

/// Reusable App Header / Navigation Bar for standard screens (Screens 09–34).
///
/// Features:
/// - SafeArea top padding aware.
/// - Configurable title & optional subtitle.
/// - Back button with customizable callback [onBackTap].
/// - Leading and trailing actions slots.
/// - Optional bottom slot (e.g. search bar, filter tabs).
/// - Optional frosted glass translucent styling.
/// - Theme-aware styling and status-bar overlay management.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final IconData backIcon;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;
  final double bottomHeight;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;
  final TextStyle? titleStyle;
  final bool? isDark;
  final bool isGlass;
  final bool centerTitle;
  final double elevation;

  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showBackButton = true,
    this.onBackTap,
    this.backIcon = Icons.arrow_back_ios_new_rounded,
    this.leading,
    this.actions,
    this.bottom,
    this.bottomHeight = 0.0,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.boxShadow,
    this.titleStyle,
    this.isDark,
    this.isGlass = false,
    this.centerTitle = true,
    this.elevation = 0.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.0 + bottomHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = isDark ?? (theme.brightness == Brightness.dark);
    final topPadding = MediaQuery.paddingOf(context).top;

    final defaultBgColor = isDarkMode
        ? AppColors.surfaceDark
        : Colors.white;

    final resolvedBgColor = backgroundColor ??
        (isGlass
            ? defaultBgColor.withValues(alpha: 0.75)
            : defaultBgColor);

    final titleColor = foregroundColor ??
        (isDarkMode
            ? AppColors.textPrimaryDark
            : const Color(0xFF0F172A));

    Widget headerContent = Container(
      decoration: BoxDecoration(
        color: resolvedBgColor,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        border: elevation > 0 || isGlass
            ? Border(
                bottom: BorderSide(
                  color: isDarkMode
                      ? AppColors.cardBorderDark.withValues(alpha: 0.6)
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                  width: 1.0,
                ),
              )
            : null,
      ),
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56.0,
            child: NavigationToolbar(
              leading: leading ??
                  (showBackButton
                      ? IconButton(
                          icon: Icon(
                            backIcon,
                            size: backIcon == Icons.arrow_back_ios_new_rounded
                                ? 18.0
                                : context.r(22.0),
                            color: foregroundColor ??
                                (isDarkMode
                                    ? AppColors.textPrimaryDark
                                    : const Color(0xFF0F172A)),
                          ),
                          onPressed: onBackTap ?? () => Navigator.of(context).maybePop(),
                        )
                      : null),
              middle: title != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: centerTitle
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: titleStyle ??
                              TextStyle(
                                fontSize: context.sp(18),
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                                fontFamily: AppTextStyles.fontFamily,
                                letterSpacing: -0.3,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: context.sp(12),
                              fontWeight: FontWeight.w400,
                              color: foregroundColor?.withValues(alpha: 0.8) ??
                                  const Color(0xFF64748B),
                              fontFamily: AppTextStyles.fontFamily,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    )
                  : null,
              trailing: actions != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    )
                  : null,
              centerMiddle: centerTitle,
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );

    if (isGlass) {
      headerContent = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
          child: headerContent,
        ),
      );
    }

    final overlayStyle = (backgroundColor == AppColors.primary || isDarkMode)
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: headerContent,
    );
  }
}
