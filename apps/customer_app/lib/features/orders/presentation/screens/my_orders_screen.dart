import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../checkout/presentation/providers/order_provider.dart';
import '../widgets/my_orders_help_card.dart';
import '../widgets/order_history_card.dart';

/// Screen 27 — My Orders screen matching 27_My_Orders.png.
class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  void _handleBack(BuildContext context) {
    HapticFeedback.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        GoRouter.of(context).go(RouteNames.profile);
      } catch (_) {
        // Fallback
      }
    }
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(customerOrdersProvider);
    await ref.read(customerOrdersProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ordersAsync = ref.watch(customerOrdersProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
      appBar: AppHeader(
        title: 'My Orders',
        showBackButton: true,
        centerTitle: false,
        backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
        foregroundColor: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22.0),
          bottomRight: Radius.circular(22.0),
        ),
        onBackTap: () => _handleBack(context),
      ),
      body: SafeArea(
        child: ordersAsync.when(
          loading: () => const Center(
            child: AppLoading(
              message: 'Loading your orders...',
            ),
          ),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppErrorState(
                title: 'Unable to load orders',
                message: 'We could not load your order history. Please check your connection and try again.',
                retryText: 'Try Again',
                onRetry: () => ref.refresh(customerOrdersProvider),
              ),
            ),
          ),
          data: (ordersRaw) {
            final orders = ordersRaw.whereType<Map<String, dynamic>>().toList();

            if (orders.isEmpty) {
              return _buildEmptyState(context, isDark);
            }

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF014D40),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: context.h(AppSpacing.md),
                ),
                itemCount: orders.length + 2, // Orders + Help Card + Footer Note
                itemBuilder: (context, index) {
                  // 1. Order History Cards
                  if (index < orders.length) {
                    final order = orders[index];
                    return OrderHistoryCard(order: order);
                  }

                  // 2. Bottom Help Card
                  if (index == orders.length) {
                    return const MyOrdersHelpCard();
                  }

                  // 3. Footer Order Count Summary Note
                  final count = orders.length;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 20.0),
                    child: Center(
                      child: Text(
                        'Showing $count ${count == 1 ? 'order' : 'orders'}',
                        style: TextStyle(
                          fontSize: context.sp(12.5),
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Screen 28 — My Orders Empty State matching 28_My_Orders_Empty.png
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF014D40),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        children: [
          SizedBox(height: context.h(40.0)),
          Center(
            child: _buildEmptyOrdersIllustration(context, isDark),
          ),
          const SizedBox(height: 28.0),
          Center(
            child: Text(
              'No orders yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.sp(22.0),
                fontWeight: FontWeight.w700,
                fontFamily: AppTextStyles.fontFamily,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'You haven\'t placed any orders yet.\nStart shopping and your orders will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.sp(14.0),
                  height: 1.45,
                  fontFamily: AppTextStyles.fontFamily,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36.0),
          AppButton(
            label: 'Start Shopping',
            variant: ButtonVariant.primary,
            size: ButtonSize.large,
            isFullWidth: true,
            onPressed: () {
              try {
                GoRouter.of(context).go(RouteNames.home);
              } catch (_) {
                // Fallback
              }
            },
          ),
          const SizedBox(height: 20.0),
          Center(
            child: Text(
              'Fresh Fruits & Vegetables, delivered to your doorstep.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.sp(12.5),
                fontWeight: FontWeight.w400,
                fontFamily: AppTextStyles.fontFamily,
                color: isDark
                    ? AppColors.textSecondaryDark.withValues(alpha: 0.7)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
          SizedBox(height: context.h(40.0)),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersIllustration(BuildContext context, bool isDark) {
    final circleSize = context.r(144.0).clamp(120.0, 160.0);
    final badgeSize = context.r(38.0).clamp(34.0, 44.0);

    return SizedBox(
      width: circleSize + 16.0,
      height: circleSize + 16.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2F3F0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomPaint(
                size: Size(circleSize * 0.55, circleSize * 0.55),
                painter: _BasketPainter(
                  strokeColor: isDark ? const Color(0xFF34D399) : const Color(0xFF014D40),
                  isDark: isDark,
                ),
              ),
            ),
          ),
          Positioned(
            right: 4.0,
            bottom: 4.0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: badgeSize * 0.5,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF014D40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the Screen 28 empty basket illustration
class _BasketPainter extends CustomPainter {
  final Color strokeColor;
  final bool isDark;

  const _BasketPainter({
    required this.strokeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final lemonPaint = Paint()
      ..color = const Color(0xFFFDE047)
      ..style = PaintingStyle.fill;

    final leafPaint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.fill;

    // 1. Lemon / Fruit peeking out from basket
    final fruitCenter = Offset(size.width * 0.44, size.height * 0.40);
    final fruitRect = Rect.fromCircle(center: fruitCenter, radius: size.width * 0.20);
    canvas.drawArc(fruitRect, 3.14, 3.14, true, lemonPaint);
    canvas.drawArc(fruitRect, 3.14, 3.14, false, strokePaint);

    // 2. Fruit Leaf
    final leafPath = Path();
    leafPath.moveTo(size.width * 0.52, size.height * 0.28);
    leafPath.quadraticBezierTo(size.width * 0.62, size.height * 0.24, size.width * 0.60, size.height * 0.34);
    leafPath.quadraticBezierTo(size.width * 0.52, size.height * 0.35, size.width * 0.52, size.height * 0.28);
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);
    canvas.drawPath(leafPath, strokePaint);

    // 3. Sparkle '+' accent
    final sparkleX = size.width * 0.70;
    final sparkleY = size.height * 0.30;
    final sLen = size.width * 0.05;
    canvas.drawLine(Offset(sparkleX - sLen, sparkleY), Offset(sparkleX + sLen, sparkleY), strokePaint);
    canvas.drawLine(Offset(sparkleX, sparkleY - sLen), Offset(sparkleX, sparkleY + sLen), strokePaint);

    // 4. Basket body trapezoid
    final basketTopLeft = Offset(size.width * 0.22, size.height * 0.48);
    final basketTopRight = Offset(size.width * 0.78, size.height * 0.48);
    final basketBottomLeft = Offset(size.width * 0.30, size.height * 0.82);
    final basketBottomRight = Offset(size.width * 0.70, size.height * 0.82);

    final basketPath = Path()
      ..moveTo(basketTopLeft.dx, basketTopLeft.dy)
      ..lineTo(basketTopRight.dx, basketTopRight.dy)
      ..lineTo(basketBottomRight.dx, basketBottomRight.dy)
      ..arcToPoint(
        Offset(basketBottomRight.dx - 4, basketBottomRight.dy + 4),
        radius: const Radius.circular(4),
      )
      ..lineTo(basketBottomLeft.dx + 4, basketBottomLeft.dy + 4)
      ..arcToPoint(
        Offset(basketBottomLeft.dx, basketBottomLeft.dy),
        radius: const Radius.circular(4),
      )
      ..close();

    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawPath(basketPath, bgPaint);
    canvas.drawPath(basketPath, strokePaint);

    // 5. Basket horizontal wire
    final midLeft = Offset(size.width * 0.26, size.height * 0.65);
    final midRight = Offset(size.width * 0.74, size.height * 0.65);
    canvas.drawLine(midLeft, midRight, strokePaint);

    // 6. Vertical grid wires
    canvas.drawLine(Offset(size.width * 0.38, size.height * 0.48), Offset(size.width * 0.42, size.height * 0.82), strokePaint);
    canvas.drawLine(Offset(size.width * 0.50, size.height * 0.48), Offset(size.width * 0.50, size.height * 0.82), strokePaint);
    canvas.drawLine(Offset(size.width * 0.62, size.height * 0.48), Offset(size.width * 0.58, size.height * 0.82), strokePaint);
  }

  @override
  bool shouldRepaint(covariant _BasketPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor || oldDelegate.isDark != isDark;
}

