import 'package:flutter/material.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/order_tracking_provider.dart';

/// Screen 21 Hero Status Banner matching 21_Order_Tracking.png.
class TrackingHeroBanner extends StatelessWidget {
  final OrderTrackingStatusHelper helper;

  const TrackingHeroBanner({
    super.key,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF013B31),
                  const Color(0xFF022B24),
                ]
              : [
                  const Color(0xFF014D40),
                  const Color(0xFF063A31),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF014D40).withValues(alpha: isDark ? 0.35 : 0.20),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Stack(
          children: [
            // Decorative Shopping Bag Watermark
            Positioned(
              top: -10,
              right: -10,
              child: Opacity(
                opacity: 0.12,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: context.r(130.0),
                  color: Colors.white,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Current Step Indicator Tag
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color: helper.isCancelled
                              ? const Color(0xFFEF4444)
                              : helper.isDelivered
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF34D399),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (helper.isCancelled
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF34D399))
                                  .withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Flexible(
                        child: Text(
                          helper.currentStepLabel,
                          style: TextStyle(
                            fontSize: context.sp(11.5),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: helper.isCancelled
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFF6EE7B7),
                            fontFamily: AppTextStyles.fontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),

                  // 2. Headline
                  Text(
                    helper.heroTitle,
                    style: TextStyle(
                      fontSize: context.sp(20.0),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: AppTextStyles.fontFamily,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // 3. Subtitle
                  Text(
                    helper.heroSubtitle,
                    style: TextStyle(
                      fontSize: context.sp(13.5),
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontFamily: AppTextStyles.fontFamily,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // 4. Estimated Arrival Pill
                  if (!helper.isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999.0),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '⚡',
                            style: TextStyle(fontSize: 13.0),
                          ),
                          const SizedBox(width: 6.0),
                          Flexible(
                            child: Text(
                              helper.estimatedArrivalText,
                              style: TextStyle(
                                fontSize: context.sp(11.5),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                fontFamily: AppTextStyles.fontFamily,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
