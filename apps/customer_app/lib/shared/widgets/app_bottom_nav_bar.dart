import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';

/// Navigation item model for [AppBottomNavBar].
class AppNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const AppNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// Reusable Floating Glass Bottom Navigation Bar for Unique Basket.
///
/// Features:
/// - Floating rounded pill (circular 999) inset from device edges.
/// - Frosted glass surface with 16.0 sigma BackdropFilter blur.
/// - Semi-transparent background allowing underlying content to diffuse softly.
/// - SafeArea bottom padding aware.
/// - Tactile micro-press feedback on tabs with active indicator styling.
class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTabSelected;
  final List<AppNavItem> items;

  static const List<AppNavItem> defaultItems = [
    AppNavItem(
      label: 'Shop',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
    ),
    AppNavItem(
      label: 'Explore',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
    ),
    AppNavItem(
      label: 'Cart',
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
    ),
    AppNavItem(
      label: 'Favorite',
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
    ),
    AppNavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  const AppBottomNavBar({
    super.key,
    this.selectedIndex = 0,
    this.onTabSelected,
    this.items = defaultItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final navBgColor = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.68)
        : Colors.white.withValues(alpha: 0.68);

    final borderColor = isDark
        ? AppColors.cardBorderDark.withValues(alpha: 0.5)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.7);

    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: bottomInset > 0 ? bottomInset : 12.0,
        top: 4.0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            height: 62.0,
            decoration: BoxDecoration(
              color: navBgColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isSelected = selectedIndex == index;
                final item = items[index];

                return Expanded(
                  child: _NavTabButton(
                    item: item,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () => onTabSelected?.call(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabButton extends StatefulWidget {
  final AppNavItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback? onTap;

  const _NavTabButton({
    required this.item,
    required this.isSelected,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_NavTabButton> createState() => _NavTabButtonState();
}

class _NavTabButtonState extends State<_NavTabButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final item = widget.item;
    final isDark = widget.isDark;

    final targetColor = isSelected
        ? const Color(0xFF014D40)
        : (isDark
            ? AppColors.textSecondaryDark
            : const Color(0xFF64748B));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 2.0,
                ),

                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 22.0,
                  color: targetColor,
                ),
              ),
              const SizedBox(height: 2.0),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: context.sp(10.5),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: targetColor,
                  fontFamily: AppTextStyles.fontFamily,
                  letterSpacing: -0.1,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
