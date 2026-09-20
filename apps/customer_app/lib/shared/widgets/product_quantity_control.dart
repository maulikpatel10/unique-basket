import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';

/// Reusable morphing Add / Quantity control for Unique Basket product cards and detail views.
///
/// Behavior & Invariants:
/// - State 0 (Add): Circular 32x32 green button with centered '+' icon.
/// - State > 0 (Quantity): Smoothly expands horizontally toward the LEFT to 80x32,
///   keeping the right '+' cap strictly anchored.
/// - Digit Switcher: When changing between numbers (1 -> 2 -> 3), only the number updates
///   with a subtle 180ms vertical slide + fade; the outer control never resizes.
/// - Reverse (1 -> 0): Smoothly collapses horizontally toward the RIGHT back to the 32x32 '+' button.
/// - Card Safety: Never triggers vertical layout shifts or parent height changes.
class ProductQuantityControl extends StatefulWidget {
  final int quantity;
  final bool? isDark;
  final VoidCallback? onAddToCart;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final double height;
  final double expandedWidth;
  final double collapsedWidth;

  const ProductQuantityControl({
    super.key,
    required this.quantity,
    this.isDark,
    this.onAddToCart,
    this.onIncrement,
    this.onDecrement,
    this.height = 32.0,
    this.expandedWidth = 80.0,
    this.collapsedWidth = 32.0,
  });

  @override
  State<ProductQuantityControl> createState() => _ProductQuantityControlState();
}

class _ProductQuantityControlState extends State<ProductQuantityControl> {
  bool _isPlusPressed = false;
  bool _isMinusPressed = false;

  void _handlePlusTap() {
    HapticFeedback.lightImpact();
    if (widget.quantity == 0) {
      widget.onAddToCart?.call();
    } else {
      widget.onIncrement?.call();
    }
  }

  void _handleMinusTap() {
    HapticFeedback.lightImpact();
    widget.onDecrement?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDark ?? (theme.brightness == Brightness.dark);
    final quantity = widget.quantity;
    final isExpanded = quantity > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      width: isExpanded ? widget.expandedWidth : widget.collapsedWidth,
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isExpanded
            ? (isDark ? AppColors.surfaceContainerDark : Colors.white)
            : const Color(0xFF014D40),
        borderRadius: BorderRadius.circular(widget.height / 2),
        border: Border.all(
          color: const Color(0xFF014D40),
          width: isExpanded ? 1.2 : 0.0,
        ),
        boxShadow: isExpanded
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF014D40).withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          // Left side: Decrement button + Centered Quantity (Fades and slides in on expand)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: widget.expandedWidth - 28.0, // Remaining width left of the 28.0 right cap
            child: IgnorePointer(
              ignoring: !isExpanded,
              child: AnimatedOpacity(
                opacity: isExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Row(
                  children: [
                    // Decrement Button with tactile press feedback
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isMinusPressed = true),
                      onTapUp: (_) => setState(() => _isMinusPressed = false),
                      onTapCancel: () => setState(() => _isMinusPressed = false),
                      onTap: _handleMinusTap,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 24.0,
                        height: widget.height,
                        child: Center(
                          child: AnimatedScale(
                            scale: _isMinusPressed ? 0.93 : 1.0,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            child: Icon(
                              Icons.remove_rounded,
                              size: 14.0,
                              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF014D40),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Centered Quantity digit shifted slightly left to maintain visual balance
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.18),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                child: child,
                              ),
                            ),
                            child: Text(
                              '$quantity',
                              key: ValueKey('qty_$quantity'),
                              style: TextStyle(
                                fontSize: context.sp(12),
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF014D40),
                                fontFamily: AppTextStyles.fontFamily,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // Right side: '+' Button (Anchored to the right)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPlusPressed = true),
              onTapUp: (_) => setState(() => _isPlusPressed = false),
              onTapCancel: () => setState(() => _isPlusPressed = false),
              onTap: _handlePlusTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedScale(
                scale: _isPlusPressed ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  width: isExpanded ? 28.0 : widget.collapsedWidth,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: const Color(0xFF014D40),
                    borderRadius: isExpanded
                        ? const BorderRadius.horizontal(
                            right: Radius.circular(14.0),
                            left: Radius.circular(14.0),
                          )
                        : BorderRadius.circular(widget.height / 2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add_rounded,
                      size: isExpanded ? 16.0 : 20.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
