import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Single page widget for Onboarding with light theme gradient overlays:
/// 1. Full-bleed background photography
/// 2. Multi-stop light mint/ivory gradient overlay matching the brand theme
/// 3. Deep dark brand typography (AppColors.primary)
class OnboardingPage extends StatefulWidget {
  final int pageIndex;
  final String imageAssetPath;
  final String title;
  final String subtitle;
  final bool isCurrentPage;

  const OnboardingPage({
    super.key,
    required this.pageIndex,
    required this.imageAssetPath,
    required this.title,
    required this.subtitle,
    this.isCurrentPage = true,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.isCurrentPage) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentPage && !oldWidget.isCurrentPage) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations && _controller.value != 1.0) {
      _controller.value = 1.0;
    }

    final headingStyle = AppTextStyles.headlineMedium.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w800,
      fontSize: context.sp(28),
      height: 1.20,
      letterSpacing: -0.5,
    );

    final bodyStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textSecondary,
      fontSize: context.sp(14),
      height: 1.40,
      fontWeight: FontWeight.w500,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // ---------------------------------------------------------------------
        // 1. FULL-SCREEN BACKGROUND IMAGE
        // ---------------------------------------------------------------------
        Image.asset(
          widget.imageAssetPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
        ),

        // ---------------------------------------------------------------------
        // 2. LIGHT MULTI-STOP GRADIENT OVERLAYS (Top Header Scrim + Bottom Fade)
        // ---------------------------------------------------------------------
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.12, 0.22, 0.50, 0.74, 1.0],
              colors: [
                Color(0xFFF7FAFA),
                Color(0xF0F7FAFA),
                Color(0x00F7FAFA),
                Color(0x00F7FAFA),
                Color(0xEEF7FAFA),
                Color(0xFFF7FAFA),
              ],
            ),
          ),
        ),

        // ---------------------------------------------------------------------
        // 3. DARK TEXT & CONTENT OVERLAY (Bottom Region with generous breathing room)
        // ---------------------------------------------------------------------
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: context.h(104),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main Heading (Dark Brand Green)
                Text(
                  widget.title,
                  style: headingStyle,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Subtitle / Description (Dark Secondary Color)
                Text(
                  widget.subtitle,
                  style: bodyStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
