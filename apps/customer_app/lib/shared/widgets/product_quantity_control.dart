import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_responsive.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/home/data/models/quantity_rule.dart';

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
/// - Quantities are decimals in the product unit (D-012), e.g. 1.25; [canIncrement]
///   is false at the product's configured maximum (the '+' cap is dimmed and inert).
class ProductQuantityControl extends StatefulWidget {
  final double quantity;
  final bool canIncrement;
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
    this.canIncrement = true,
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
  void _handlePlusTap() {
    if (widget.quantity > 0 && !widget.canIncrement) return;
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

    final circleSize = widget.height;
    final iconSize = (widget.height * 0.45).clamp(14.0, 20.0);
    final collapsedIconSize = (widget.height * 0.56).clamp(18.0, 22.0);
    final fontSize = (widget.height * 0.38).clamp(12.0, 16.0);

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
          width: isExpanded ? 1.0 : 0.0,
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
          // Left side: Decrement button + Perfectly Centered Quantity (Fades and slides in on expand)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: widget.expandedWidth - circleSize,
            child: IgnorePointer(
              ignoring: !isExpanded,
              child: AnimatedOpacity(
                opacity: isExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Row(
                  children: [
                    // Decrement Button with centered icon
                    GestureDetector(
                      onTap: _handleMinusTap,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: circleSize,
                        height: widget.height,
                        child: Center(
                          child: Icon(
                            Icons.remove_rounded,
                            size: iconSize,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF014D40),
                          ),
                        ),
                      ),
                    ),

                    // Optically Centered Quantity digit (shifted slightly left away from solid green plus cap)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
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
                            child: FittedBox(
                              key: ValueKey('qty_$quantity'),
                              fit: BoxFit.scaleDown,
                              child: Text(
                                QuantityRule.format(quantity),
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: context.sp(fontSize),
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF014D40),
                                  fontFamily: AppTextStyles.fontFamily,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right side: '+' Button (Seamless circular cap anchored to the right with zero white space gap)
          Positioned(
            right: -1.0,
            top: 0,
            bottom: -1.0,
            child: GestureDetector(
              onTap: _handlePlusTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                width: isExpanded ? circleSize + 1.0 : widget.collapsedWidth + 2.0,
                height: widget.height + 2.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF014D40).withValues(alpha: isExpanded && !widget.canIncrement ? 0.4 : 1.0),
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    semanticLabel: isExpanded && !widget.canIncrement ? 'Maximum quantity reached' : null,
                    size: isExpanded ? iconSize : collapsedIconSize,
                    color: Colors.white,
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
