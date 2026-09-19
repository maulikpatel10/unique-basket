import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';

/// Screen 08 (Home) Bottom Navigation Bar.
///
/// Delegates to the reusable [AppBottomNavBar] widget while maintaining backward compatibility.
class HomeBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTabSelected;

  const HomeBottomNavBar({
    super.key,
    this.selectedIndex = 0,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomNavBar(
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
    );
  }
}
