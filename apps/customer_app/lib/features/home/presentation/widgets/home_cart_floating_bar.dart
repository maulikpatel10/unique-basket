import 'package:flutter/material.dart';
import '../../../../shared/widgets/checkout_bar.dart';

/// Screen 08 (Home) Floating Checkout Bar.
///
/// Delegates to the reusable [CheckoutBar] widget while maintaining backward compatibility.
class HomeCartFloatingBar extends StatelessWidget {
  final int itemCount;
  final double totalPrice;
  final VoidCallback? onCheckoutTap;

  const HomeCartFloatingBar({
    super.key,
    required this.itemCount,
    required this.totalPrice,
    this.onCheckoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return CheckoutBar(
      itemCount: itemCount,
      totalPrice: totalPrice,
      onCheckoutTap: onCheckoutTap,
    );
  }
}
