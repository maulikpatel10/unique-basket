import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_search_bar.dart';

/// SliverPersistentHeaderDelegate that implements the collapsing header and
/// blur-translucent pinned search bar interaction for Screen 08 (Home).
///
/// Behavior:
/// - Initial: Full green header with delivery address, distance badge, notification icon, and search bar.
/// - Scroll up: Address row fades out and moves up, header background transitions from brand green to frosted blur translucent.
/// - Pinned: Search bar remains fixed at top below status bar with frosted glass blur transparent background.
/// - Scroll down: Header smoothly expands and restores.
class HomeHeaderSliverDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final String deliveryTitle;
  final String deliveryAddress;
  final String? distanceText;
  final VoidCallback? onAddressTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onMicTap;

  const HomeHeaderSliverDelegate({
    required this.topPadding,
    this.deliveryTitle = 'Home',
    this.deliveryAddress = '',
    this.distanceText,
    this.onAddressTap,
    this.onNotificationTap,
    this.onSearchTap,
    this.onMicTap,
  });

  @override
  double get maxExtent => topPadding + 178.0;

  @override
  double get minExtent => topPadding + 66.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final delta = maxExtent - minExtent;
    final progress = (shrinkOffset / (delta > 0 ? delta : 1.0)).clamp(0.0, 1.0);

    // Dynamic blur-translucent color transitions
    final primaryHeaderColor =
        isDark ? const Color(0xFF002922) : AppColors.primary;
    final pinnedBgColor = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.70)
        : Colors.white.withValues(alpha: 0.70);

    final headerBgColor =
        Color.lerp(primaryHeaderColor, pinnedBgColor, progress) ??
            primaryHeaderColor;

    // Address section opacity and vertical translation
    final addressOpacity = (1.0 - progress * 1.8).clamp(0.0, 1.0);
    final addressOffset = -18.0 * progress;

    // Bottom radius collapses smoothly
    final bottomRadius = 20.0 * (1.0 - progress);

    // Bottom margin for search bar
    final searchBottomMargin = 14.0 * (1.0 - progress) + 8.0 * progress;

    // System overlay style based on progress and brightness
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
        : (progress > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18.0 * progress,
            sigmaY: 18.0 * progress,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(bottomRadius),
                bottomRight: Radius.circular(bottomRadius),
              ),
              border: progress > 0.85
                  ? Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppColors.cardBorderDark.withValues(alpha: 0.6)
                            : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                        width: 1.0,
                      ),
                    )
                  : null,
              boxShadow: progress > 0.1
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06 * progress),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Top Delivery Address & Notification Bell Row (Collapsing)
                if (addressOpacity > 0.0)
                  Positioned(
                    top: topPadding + 8.0 + addressOffset,
                    left: context.r(AppSpacing.md),
                    right: context.r(AppSpacing.md),
                    child: Opacity(
                      opacity: addressOpacity,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Address & Distance Column
                          Expanded(
                            child: InkWell(
                              onTap: onAddressTap,
                              borderRadius: BorderRadius.circular(12.0),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Delivering to',
                                      style: TextStyle(
                                        fontSize: context.sp(12),
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white
                                            .withValues(alpha: 0.75),
                                        fontFamily: AppTextStyles.fontFamily,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            deliveryAddress.isNotEmpty
                                                ? '$deliveryTitle - $deliveryAddress'
                                                : deliveryTitle,
                                            style: TextStyle(
                                              fontSize: context.sp(16),
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              letterSpacing: -0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4.0),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white,
                                          size: 18.0,
                                        ),
                                      ],
                                    ),
                                    if (distanceText != null &&
                                        distanceText!.isNotEmpty) ...[
                                      const SizedBox(height: 6.0),
                                      // Distance pill badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(16.0),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.25),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.storefront_outlined,
                                              color: Colors.white,
                                              size: 13.0,
                                            ),
                                            const SizedBox(width: 4.0),
                                            Text(
                                              distanceText!,
                                              style: TextStyle(
                                                fontSize: context.sp(11),
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                fontFamily:
                                                    AppTextStyles.fontFamily,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Notification Bell Icon Button
                          IconButton(
                            key: const Key('home_notification_button'),
                            onPressed: onNotificationTap,
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 24.0,
                            ),
                            padding: const EdgeInsets.all(8.0),
                            constraints: const BoxConstraints(
                              minWidth: 44.0,
                              minHeight: 44.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 2. Search Bar (Moves upward and stays PINNED at bottom: searchBottomMargin)
                Positioned(
                  left: context.r(AppSpacing.md),
                  right: context.r(AppSpacing.md),
                  bottom: searchBottomMargin,
                  child: _HomeSearchBar(
                    progress: progress,
                    isDark: isDark,
                    onSearchTap: onSearchTap,
                    onMicTap: onMicTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant HomeHeaderSliverDelegate oldDelegate) {
    return topPadding != oldDelegate.topPadding ||
        deliveryTitle != oldDelegate.deliveryTitle ||
        deliveryAddress != oldDelegate.deliveryAddress ||
        distanceText != oldDelegate.distanceText ||
        onAddressTap != oldDelegate.onAddressTap ||
        onNotificationTap != oldDelegate.onNotificationTap ||
        onSearchTap != oldDelegate.onSearchTap ||
        onMicTap != oldDelegate.onMicTap;
  }
}

/// Standalone / Reusable Home Search Bar widget with blur translucent support.
class _HomeSearchBar extends StatelessWidget {
  final double progress;
  final bool isDark;
  final VoidCallback? onSearchTap;
  final VoidCallback? onMicTap;

  const _HomeSearchBar({
    required this.progress,
    required this.isDark,
    this.onSearchTap,
    this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSearchBar(
      height: context.r(48),
      onTap: onSearchTap,
      onTrailingTap: onMicTap ?? onSearchTap,
      isGlass: true,
      readOnly: true,
    );
  }
}

/// Standalone HomeHeader widget for backward compatibility or non-sliver contexts.
class HomeHeader extends StatelessWidget {
  final String deliveryTitle;
  final String deliveryAddress;
  final String? distanceText;
  final VoidCallback? onAddressTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onMicTap;

  const HomeHeader({
    super.key,
    this.deliveryTitle = 'Home',
    this.deliveryAddress = '',
    this.distanceText,
    this.onAddressTap,
    this.onNotificationTap,
    this.onSearchTap,
    this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerBgColor = isDark ? const Color(0xFF002922) : AppColors.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: headerBgColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: context.r(AppSpacing.md),
            right: context.r(AppSpacing.md),
            top: context.r(AppSpacing.sm),
            bottom: context.r(14.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Delivery Address Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onAddressTap,
                      borderRadius: BorderRadius.circular(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Delivering to',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: context.sp(11.5),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppTextStyles.fontFamily,
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 16.0,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  deliveryAddress.isNotEmpty
                                      ? '$deliveryTitle - $deliveryAddress'
                                      : deliveryTitle,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.sp(14.5),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: AppTextStyles.fontFamily,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (distanceText != null &&
                                  distanceText!.isNotEmpty) ...[
                                const SizedBox(width: 6.0),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    distanceText!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: context.sp(10),
                                      fontWeight: FontWeight.w600,
                                      fontFamily: AppTextStyles.fontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('home_notification_button'),
                    onPressed: onNotificationTap,
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 22.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Reusable Search Bar
              AppSearchBar(
                height: context.r(48),
                onTap: onSearchTap,
                onTrailingTap: onMicTap ?? onSearchTap,
                isGlass: true,
                readOnly: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
