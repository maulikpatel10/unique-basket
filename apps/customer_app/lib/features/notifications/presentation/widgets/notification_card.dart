import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onActionTap,
  });

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '$formattedHour:$minute $period';

    if (difference.inDays == 0 && now.day == dateTime.day) {
      return timeStr;
    } else if (difference.inDays <= 1 ||
        (now.day - dateTime.day == 1 && now.month == dateTime.month)) {
      return 'Yesterday • $timeStr';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final monthStr = months[dateTime.month - 1];
      return '$monthStr ${dateTime.day} • $timeStr';
    }
  }

  Widget _buildLeadingIcon(BuildContext context, bool isDark) {
    IconData iconData = Icons.notifications_none_rounded;
    Color bgColor = AppColors.primary;
    Color iconColor = Colors.white;

    final titleLower = notification.title.toLowerCase();
    final isDelivered = titleLower.contains('delivered') ||
        notification.body.toLowerCase().contains('delivered');

    switch (notification.type) {
      case NotificationType.orderStatus:
        if (isDelivered) {
          iconData = Icons.check_circle_outline_rounded;
          bgColor = isDark ? const Color(0xFF00382E) : const Color(0xFFE6F4EA);
          iconColor =
              isDark ? const Color(0xFF34D399) : const Color(0xFF014D40);
        } else {
          iconData = Icons.shopping_bag_outlined;
          bgColor = AppColors.primary;
        }
        break;
      case NotificationType.deliveryDispatch:
        iconData = Icons.two_wheeler_rounded;
        bgColor = const Color(0xFF00796B);
        break;
      case NotificationType.promotion:
        iconData = Icons.local_offer_outlined;
        bgColor = const Color(0xFF2E7D32);
        break;
      case NotificationType.accountActivity:
        iconData = Icons.person_outline_rounded;
        bgColor = const Color(0xFF0288D1);
        break;
      case NotificationType.welcome:
        iconData = Icons.verified_user_outlined;
        bgColor = AppColors.primary;
        break;
      case NotificationType.general:
        iconData = Icons.notifications_none_rounded;
        bgColor = AppColors.primary;
        break;
    }

    return Container(
      width: context.w(44),
      height: context.w(44),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: context.sp(22.0),
          color: iconColor,
        ),
      ),
    );
  }

  void _handleDefaultNavigation(BuildContext context) {
    if (notification.orderId != null && notification.orderId!.isNotEmpty) {
      final isDelivered = notification.title.toLowerCase().contains('delivered') ||
          notification.body.toLowerCase().contains('delivered');

      final extraData = {
        'orderId': notification.orderId,
        'orderNumber': notification.orderNumber,
      };

      try {
        if (isDelivered) {
          GoRouter.of(context).push(RouteNames.orderDetails, extra: extraData);
        } else {
          GoRouter.of(context).push(RouteNames.orderTracking, extra: extraData);
        }
      } catch (_) {
        // Safe navigation catch for tests without router
      }
    } else if (notification.promoCode != null &&
        notification.promoCode!.isNotEmpty) {
      try {
        GoRouter.of(context).push(RouteNames.explore);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark
        ? (notification.isRead ? AppColors.cardDark : const Color(0xFF142220))
        : (notification.isRead ? Colors.white : const Color(0xFFFAFDFA));

    final borderColor = isDark
        ? (notification.isRead
            ? AppColors.surfaceContainerDark
            : const Color(0xFF036957))
        : (notification.isRead
            ? const Color(0xFFE2E8F0)
            : const Color(0xFFB5DDD8));

    final tagText = notification.tag ??
        notification.orderNumber ??
        (notification.type == NotificationType.deliveryDispatch
            ? 'Delivery Dispatch'
            : (notification.type == NotificationType.promotion
                ? 'Fresh Offer'
                : (notification.type == NotificationType.accountActivity
                    ? 'Account Activity'
                    : (notification.type == NotificationType.welcome
                        ? 'Welcome'
                        : null))));

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: context.h(5.0),
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: borderColor,
          width: notification.isRead ? 1.0 : 1.2,
        ),
        boxShadow: notification.isRead
            ? null
            : [
                BoxShadow(
                  color: (isDark ? Colors.black : const Color(0xFF014D40))
                      .withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            onTap?.call();
            _handleDefaultNavigation(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeadingIcon(context, isDark),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag, timestamp & unread dot row
                      Row(
                        children: [
                          if (tagText != null && tagText.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceContainerDark
                                    : const Color(0xFFE7F5F4),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                tagText,
                                style: TextStyle(
                                  fontSize: context.sp(11.0),
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.primaryUltraLight
                                      : const Color(0xFF014D40),
                                ),
                              ),
                            ),
                            const Spacer(),
                          ] else
                            const Spacer(),
                          Text(
                            _formatTimestamp(notification.createdAt),
                            style: TextStyle(
                              fontSize: context.sp(11.5),
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 6.0),
                            Container(
                              width: 7.0,
                              height: 7.0,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00796B),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      // Title
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: context.sp(14.5),
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      // Message body
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: context.sp(13.0),
                          height: 1.35,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF64748B),
                        ),
                      ),
                      // Action Row if applicable
                      if (notification.orderId != null &&
                          notification.orderId!.isNotEmpty) ...[
                        const SizedBox(height: 8.0),
                        _buildOrderActionRow(context, isDark),
                      ] else if (notification.promoCode != null &&
                          notification.promoCode!.isNotEmpty) ...[
                        const SizedBox(height: 8.0),
                        _buildPromoActionRow(context, isDark),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderActionRow(BuildContext context, bool isDark) {
    final isDelivered = notification.title.toLowerCase().contains('delivered') ||
        notification.body.toLowerCase().contains('delivered');

    return Row(
      children: [
        Text(
          isDelivered ? 'View Receipt & Invoice ›' : 'Track Live Order →',
          style: TextStyle(
            fontSize: context.sp(13.0),
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF34D399) : const Color(0xFF014D40),
          ),
        ),
        if (!isDelivered) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '• Est. arrival 8–15 min',
            style: TextStyle(
              fontSize: context.sp(11.5),
              color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPromoActionRow(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF1F8F5),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark ? const Color(0xFF036957) : const Color(0xFFB5DDD8),
          width: 0.8,
        ),
      ),
      child: Text(
        'Use Code: ${notification.promoCode}',
        style: TextStyle(
          fontSize: context.sp(12.0),
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF34D399) : const Color(0xFF014D40),
        ),
      ),
    );
  }
}
