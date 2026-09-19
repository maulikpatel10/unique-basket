import 'package:flutter/material.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';

/// Reusable Floating Checkout Pill Bar for Unique Basket.
///
/// Features:
/// - Floating centered pill appearance with responsive width constraint.
/// - Brand green (#014D40) background with multi-layer soft drop shadow.
/// - Left: product count and price.
/// - Right: white pill Checkout button with shopping bag icon and tactile press scale.
/// - Automatically returns [SizedBox.shrink] when [itemCount] <= 0.
class CheckoutBar extends StatelessWidget {
  final int itemCount;
  final double totalPrice;
  final VoidCallback? onCheckoutTap;
  final String currencySymbol;
  final String? customLabel;

  const CheckoutBar({
    super.key,
    required this.itemCount,
    required this.totalPrice,
    this.onCheckoutTap,
    this.currencySymbol = '\$',
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();

    final itemLabel = customLabel ?? (itemCount == 1 ? '1 Product' : '$itemCount Products');
    final double maxBarWidth = context.r(310.0).clamp(270.0, 340.0);

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxBarWidth,
          minHeight: 50.0,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 7.0,
          top: 6.0,
          bottom: 6.0,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF014D40),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF014D40).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Product count & Total price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  itemLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: context.sp(10.5),
                    fontWeight: FontWeight.w500,
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                Text(
                  '$currencySymbol${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.sp(15.5),
                    fontWeight: FontWeight.w800,
                    fontFamily: AppTextStyles.fontFamily,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14.0),

            // Right: Checkout Button
            _CheckoutButton(
              onTap: onCheckoutTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutButton extends StatefulWidget {
  final VoidCallback? onTap;

  const _CheckoutButton({this.onTap});

  @override
  State<_CheckoutButton> createState() => _CheckoutButtonState();
}

class _CheckoutButtonState extends State<_CheckoutButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Checkout',
                style: TextStyle(
                  color: const Color(0xFF014D40),
                  fontSize: context.sp(13),
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
              const SizedBox(width: 5.0),
              const Icon(
                Icons.shopping_bag_outlined,
                size: 15.0,
                color: Color(0xFF014D40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
