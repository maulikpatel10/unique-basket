import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/order_tracking_provider.dart';

/// 5-Stage Order Progress Timeline Widget matching 21_Order_Tracking.png.
class OrderProgressTimeline extends StatelessWidget {
  final OrderTrackingStatusHelper helper;
  final String? createdAt;
  final String? destinationCity;

  const OrderProgressTimeline({
    super.key,
    required this.helper,
    this.createdAt,
    this.destinationCity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formattedConfirmedTime = _formatTime(createdAt);
    final cityText = destinationCity != null && destinationCity!.isNotEmpty
        ? destinationCity!
        : 'Ahmedabad';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Label
          Text(
            'ORDER PROGRESS',
            style: TextStyle(
              fontSize: context.sp(12.0),
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
              letterSpacing: 0.8,
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
          const SizedBox(height: 20.0),

          // Cancelled State Notice Banner
          if (helper.isCancelled)
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 22.0),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      'Order Cancelled. Progress has been discontinued.',
                      style: TextStyle(
                        fontSize: context.sp(13.0),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF991B1B),
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 5-Stage Timeline Nodes
          _buildTimelineNode(
            context: context,
            stageNumber: 1,
            title: 'Order Confirmed',
            subtext: 'Your order has been received & payment verified',
            rightLabel: formattedConfirmedTime,
            isFirst: true,
            isLast: false,
            isDark: isDark,
          ),
          _buildTimelineNode(
            context: context,
            stageNumber: 2,
            title: 'Preparing Your Order',
            subtext: helper.dynamicPackingDescription,
            hasNowBadge: helper.getNodeState(2) == TimelineNodeState.current,
            rightLabel: helper.getNodeState(2) == TimelineNodeState.current ? 'In Progress' : null,
            isFirst: false,
            isLast: false,
            isDark: isDark,
          ),
          _buildTimelineNode(
            context: context,
            stageNumber: 3,
            title: 'Ready for Pickup',
            subtext: 'Assigned delivery partner will collect',
            hasNowBadge: helper.getNodeState(3) == TimelineNodeState.current,
            rightLabel: helper.getNodeState(3) == TimelineNodeState.current ? 'In Progress' : null,
            isFirst: false,
            isLast: false,
            isDark: isDark,
          ),
          _buildTimelineNode(
            context: context,
            stageNumber: 4,
            title: 'Out for Delivery',
            subtext: 'Rider details will appear once dispatched',
            hasNowBadge: helper.getNodeState(4) == TimelineNodeState.current,
            rightLabel: helper.getNodeState(4) == TimelineNodeState.current ? 'In Progress' : null,
            isFirst: false,
            isLast: false,
            isDark: isDark,
          ),
          _buildTimelineNode(
            context: context,
            stageNumber: 5,
            title: 'Delivered',
            subtext: 'At your doorstep (Home • $cityText)',
            hasNowBadge: false,
            rightLabel: helper.isDelivered ? 'Complete' : null,
            isFirst: false,
            isLast: true,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required BuildContext context,
    required int stageNumber,
    required String title,
    required String subtext,
    String? rightLabel,
    bool hasNowBadge = false,
    required bool isFirst,
    required bool isLast,
    required bool isDark,
  }) {
    final state = helper.getNodeState(stageNumber);

    Color lineColor;
    if (state == TimelineNodeState.completed) {
      lineColor = const Color(0xFF014D40);
    } else {
      lineColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Node Icon & Connecting Line
          Column(
            children: [
              _buildNodeIcon(state, isDark),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.0,
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    color: lineColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14.0),

          // Right: Content Details
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0.0 : 22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row with optional NOW badge & right status/time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title + Badge
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: context.sp(14.5),
                                  fontWeight: state == TimelineNodeState.pending
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                                  color: state == TimelineNodeState.pending
                                      ? (isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8))
                                      : (isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A)),
                                  fontFamily: AppTextStyles.fontFamily,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasNowBadge) ...[
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Text(
                                  'NOW',
                                  style: TextStyle(
                                    fontSize: context.sp(10.5),
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF014D40),
                                    fontFamily: AppTextStyles.fontFamily,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Right Timestamp / Status
                      if (rightLabel != null && rightLabel.isNotEmpty) ...[
                        const SizedBox(width: 8.0),
                        Text(
                          rightLabel,
                          style: TextStyle(
                            fontSize: context.sp(12.0),
                            fontWeight: state == TimelineNodeState.current
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: state == TimelineNodeState.current
                                ? const Color(0xFF014D40)
                                : (isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8)),
                            fontFamily: AppTextStyles.fontFamily,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3.0),

                  // Subtitle / Dynamic Details
                  Text(
                    subtext,
                    style: TextStyle(
                      fontSize: context.sp(12.5),
                      fontWeight: FontWeight.w400,
                      color: state == TimelineNodeState.pending
                          ? (isDark
                              ? AppColors.textSecondaryDark.withValues(alpha: 0.7)
                              : const Color(0xFFA0AEC0))
                          : (isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                      fontFamily: AppTextStyles.fontFamily,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeIcon(TimelineNodeState state, bool isDark) {
    switch (state) {
      case TimelineNodeState.completed:
        return Container(
          width: 24.0,
          height: 24.0,
          decoration: const BoxDecoration(
            color: Color(0xFF014D40),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              size: 15.0,
              color: Colors.white,
            ),
          ),
        );

      case TimelineNodeState.current:
        return Container(
          width: 24.0,
          height: 24.0,
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF014D40),
              width: 2.5,
            ),
          ),
          child: Center(
            child: Container(
              width: 8.0,
              height: 8.0,
              decoration: const BoxDecoration(
                color: Color(0xFF014D40),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );

      case TimelineNodeState.pending:
        return Container(
          width: 24.0,
          height: 24.0,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              width: 2.0,
            ),
          ),
          child: Center(
            child: Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
    }
  }

  static String? _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final dateTime = DateTime.parse(raw).toLocal();
      return DateFormat('h:mm a').format(dateTime);
    } catch (_) {
      return null;
    }
  }
}
