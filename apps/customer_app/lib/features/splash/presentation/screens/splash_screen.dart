import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/startup_state_resolver.dart';

/// Production Splash Screen for Unique Basket Customer App.
///
/// Accurately reproduces the approved 00_Splash visual design reference:
/// - Clean background
/// - Centered official UNIQUE BASKET brand logo asset
/// - Subtle entrance transition (fade + subtle 0.96 -> 1.0 scale)
/// - Asynchronous startup state resolution for new, incomplete, and returning users
/// - Lifecycle-safe navigation to the resolved startup destination route.
class SplashScreen extends ConsumerStatefulWidget {
  /// Logo asset path.
  static const String logoAssetPath = 'assets/logos/unique_basket_logo.png';

  /// Target display duration before navigating to the next route.
  final Duration splashDuration;

  /// Animation duration for the entrance transition.
  final Duration animationDuration;

  /// Optional navigation callback override (useful for testing).
  final VoidCallback? onNavigate;

  /// Optional callback receiving the resolved StartupDestination (useful for testing).
  final ValueChanged<StartupDestination>? onDestinationResolved;

  const SplashScreen({
    super.key,
    this.splashDuration = const Duration(milliseconds: 1200),
    this.animationDuration = const Duration(milliseconds: 500),
    this.onNavigate,
    this.onDestinationResolved,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _navigationTimer;
  StartupDestination? _resolvedDestination;
  bool _timerElapsed = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Subtle scale matching 0.96 -> 1.0 resting state
    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSplashFlow();
      _resolveStartupDestination();
    });
  }

  void _startSplashFlow() {
    if (!mounted) return;

    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }

    _navigationTimer = Timer(widget.splashDuration, () {
      _timerElapsed = true;
      _attemptNavigation();
    });
  }

  Future<void> _resolveStartupDestination() async {
    try {
      final resolver = ref.read(startupStateResolverProvider);
      final destination = await resolver.resolve();
      if (mounted) {
        _resolvedDestination = destination;
        _attemptNavigation();
      }
    } catch (_) {
      if (mounted) {
        _resolvedDestination = StartupDestination.onboarding;
        _attemptNavigation();
      }
    }
  }

  void _attemptNavigation() {
    if (!mounted || _hasNavigated) return;

    // Navigate only when both timer has elapsed and startup state has resolved
    if (_timerElapsed && _resolvedDestination != null) {
      _hasNavigated = true;

      if (widget.onDestinationResolved != null) {
        widget.onDestinationResolved!(_resolvedDestination!);
      }

      if (widget.onNavigate != null) {
        widget.onNavigate!();
        return;
      }

      try {
        GoRouter.of(context).go(_resolvedDestination!.routeName);
      } catch (_) {
        // Safe fallback when running outside GoRouter context
      }
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Proportional logo sizing matching 00_Splash design reference (239px on 390px baseline)
    final logoWidth = context.r(239);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                SplashScreen.logoAssetPath,
                width: logoWidth,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
