import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_section_header.dart';

class _NotificationGroup {
  final String title;
  final String dateText;
  final List<NotificationModel> items;

  const _NotificationGroup({
    required this.title,
    required this.dateText,
    required this.items,
  });
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  List<_NotificationGroup> _groupNotifications(List<NotificationModel> list) {
    if (list.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <NotificationModel>[];
    final yesterdayItems = <NotificationModel>[];
    final earlierItems = <NotificationModel>[];

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

    for (final item in list) {
      final itemDate = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );

      if (itemDate.isAtSameMomentAs(today)) {
        todayItems.add(item);
      } else if (itemDate.isAtSameMomentAs(yesterday)) {
        yesterdayItems.add(item);
      } else {
        earlierItems.add(item);
      }
    }


    final groups = <_NotificationGroup>[];

    if (todayItems.isNotEmpty) {
      final dateText = '${months[now.month - 1]} ${now.day}';
      groups.add(_NotificationGroup(
        title: 'TODAY',
        dateText: dateText,
        items: todayItems,
      ));
    }

    if (yesterdayItems.isNotEmpty) {
      final yesterday = now.subtract(const Duration(days: 1));
      final dateText = '${months[yesterday.month - 1]} ${yesterday.day}';
      groups.add(_NotificationGroup(
        title: 'YESTERDAY',
        dateText: dateText,
        items: yesterdayItems,
      ));
    }

    if (earlierItems.isNotEmpty) {
      final earliest = earlierItems.first.createdAt;
      final dateText = '${months[earliest.month - 1]} ${earliest.day}';
      groups.add(_NotificationGroup(
        title: 'EARLIER',
        dateText: dateText,
        items: earlierItems,
      ));
    }

    return groups;
  }

  Widget _buildTopUnreadPill(
    BuildContext context,
    int unreadCount,
    bool isDark,
    WidgetRef ref,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: context.h(AppSpacing.xs),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF00382E) : const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF036957) : const Color(0xFFCDECE9),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.0,
            height: 7.0,
            decoration: const BoxDecoration(
              color: Color(0xFF00796B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            '$unreadCount unread ${unreadCount == 1 ? 'notification' : 'notifications'}',
            style: TextStyle(
              fontSize: context.sp(13.0),
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF014D40),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () =>
                ref.read(notificationNotifierProvider.notifier).markAllAsRead(),
            child: Text(
              'Mark all read',
              style: TextStyle(
                fontSize: context.sp(12.0),
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.primaryUltraLight : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNotice(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: context.h(AppSpacing.lg),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceContainerDark
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.done_all_rounded,
              size: 20.0,
              color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            "You're all caught up with your latest updates",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.sp(13.5),
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Notifications older than 30 days are automatically archived.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.sp(12.0),
              color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
      appBar: AppHeader(
        title: 'Notifications',
        showBackButton: true,
        centerTitle: false,
        backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
        foregroundColor: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22.0),
          bottomRight: Radius.circular(22.0),
        ),
        onBackTap: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            GoRouter.of(context).go(RouteNames.home);
          }
        },
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const AppLoading(message: 'Loading notifications...');
          }

          if (state.errorMessage != null && state.notifications.isEmpty) {
            return AppErrorState(
              title: 'Unable to Load Notifications',
              message: state.errorMessage!,
              onRetry: () => ref
                  .read(notificationNotifierProvider.notifier)
                  .loadNotifications(),
            );
          }

          if (state.isEmpty) {
            return AppEmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No Notifications Yet',
              message:
                  'Your order updates, delivery status, and fresh harvest offers will appear here.',
              actionText: 'Explore Fresh Catalog',
              onAction: () {
                try {
                  GoRouter.of(context).go(RouteNames.explore);
                } catch (_) {}
              },
            );
          }

          final grouped = _groupNotifications(state.notifications);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(notificationNotifierProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xl,
              ),
              children: [
                if (state.unreadCount > 0)
                  _buildTopUnreadPill(
                    context,
                    state.unreadCount,
                    isDark,
                    ref,
                  ),
                for (final group in grouped) ...[
                  NotificationSectionHeader(
                    title: group.title,
                    dateText: group.dateText,
                  ),
                  for (final item in group.items)
                    NotificationCard(
                      notification: item,
                      onTap: () => ref
                          .read(notificationNotifierProvider.notifier)
                          .markAsRead(item.id),
                    ),
                ],
                _buildFooterNotice(context, isDark),
              ],
            ),
          );
        },
      ),
    );
  }
}
