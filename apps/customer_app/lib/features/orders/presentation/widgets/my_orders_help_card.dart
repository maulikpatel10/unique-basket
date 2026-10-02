import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Presentation card displaying the customer support prompt at the bottom of Screen 27 (27_My_Orders.png).
class MyOrdersHelpCard extends StatelessWidget {
  final VoidCallback? onHelpTap;

  const MyOrdersHelpCard({
    super.key,
    this.onHelpTap,
  });

  void _defaultHelpAction(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support: Please call +91 98765 43210 or email support@uniquebasket.com'),
        duration: Duration(seconds: 3),
        backgroundColor: Color(0xFF014D40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Help Question Mark Icon in Teal Circle
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF134E4A) : const Color(0xFFE0F2F1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: isDark ? AppColors.primaryUltraLight : const Color(0xFF00695C),
              size: 24.0,
            ),
          ),
          const SizedBox(width: 14.0),

          // 2. Title and Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Need help with an order?',
                  style: TextStyle(
                    fontSize: context.sp(14.0),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Chat with our customer support team',
                  style: TextStyle(
                    fontSize: context.sp(12.0),
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),

          // 3. Outlined Help Button
          OutlinedButton(
            onPressed: onHelpTap ?? () => _defaultHelpAction(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? AppColors.primaryUltraLight : const Color(0xFF014D40),
              side: BorderSide(
                color: isDark ? AppColors.primaryUltraLight : const Color(0xFF014D40),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              minimumSize: const Size(60, 36),
            ),
            child: Text(
              'Help',
              style: TextStyle(
                fontSize: context.sp(13.0),
                fontWeight: FontWeight.w700,
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
