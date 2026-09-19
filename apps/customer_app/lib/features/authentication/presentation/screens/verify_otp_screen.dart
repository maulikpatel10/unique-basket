import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

/// Screen 05 — Verify Mobile OTP for Unique Basket Customer App.
///
/// Accurately reproduces the approved 05_Verify_Mobile_OTP design reference:
/// - Top bar: Circular back button + Centered Logo + "Step 2 of 2" pill badge
/// - Bold left-aligned heading + subtitle
/// - Mobile number display pill with edit pencil icon
/// - 6-digit OTP input boxes with focus highlighting and digit placeholders
/// - Resend OTP countdown pill and "Didn't receive code? Resend SMS" link
/// - Security info with lock icon
/// - "100% Farm-Fresh Fruits & Vegetables" trust badge
/// - Primary "Verify & Continue →" CTA button with loading and error states
class VerifyOtpScreen extends ConsumerStatefulWidget {
  /// Logo asset path constant.
  static const String logoAssetPath = 'assets/logos/unique_basket_logo.png';

  /// Initial phone number passed from Screen 04.
  final String? phoneNumber;

  /// Optional completion callback (useful for testing without GoRouter).
  final ValueChanged<Map<String, dynamic>>? onVerified;

  /// Optional resend callback (useful for testing).
  final VoidCallback? onResendRequested;

  /// Optional callback when user taps edit mobile number (defaults to handleBack).
  final VoidCallback? onEditPhoneRequested;

  const VerifyOtpScreen({
    super.key,
    this.phoneNumber,
    this.onVerified,
    this.onResendRequested,
    this.onEditPhoneRequested,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  static const int _otpLength = 4;
  static const int _resendInitialCountdown = 30;

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _countdownTimer;
  int _secondsRemaining = _resendInitialCountdown;
  bool _canResend = false;
  String? _clientValidationError;

  late AnimationController _cursorAnimationController;

  @override
  void initState() {
    super.initState();
    _cursorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _otpController.addListener(_handleOtpChanged);
    _startCountdown();

    // Auto-focus OTP input after transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = _resendInitialCountdown;
      _canResend = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _secondsRemaining = 0;
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _handleOtpChanged() {
    if (_clientValidationError != null) {
      setState(() {
        _clientValidationError = null;
      });
    }
    ref.read(authNotifierProvider.notifier).clearError();
    setState(() {});

    // Automatically verify when all digits entered
    if (_otpController.text.length == _otpLength) {
      _handleVerify();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _cursorAnimationController.dispose();
    _otpController.removeListener(_handleOtpChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  String _getEffectivePhoneNumber() {
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      return widget.phoneNumber!;
    }
    final authStatePhone = ref.read(authNotifierProvider).phoneNumber;
    if (authStatePhone != null && authStatePhone.isNotEmpty) {
      return authStatePhone;
    }
    return '+919876543210';
  }

  String _getFormattedDisplayPhone() {
    final raw = _getEffectivePhoneNumber().replaceAll(RegExp(r'\D'), '');
    final digits = raw.length > 10 ? raw.substring(raw.length - 10) : raw;
    if (digits.length >= 5) {
      final firstPart = digits.substring(0, 5);
      return '+91 $firstPart •••••';
    }
    return '+91 $digits •••••';
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length < _otpLength) {
      setState(() {
        _clientValidationError = 'Please enter complete 4-digit OTP';
      });
      return;
    }

    final authState = ref.read(authNotifierProvider);
    if (authState.isVerifying) return;

    _otpFocusNode.unfocus();

    final phone = _getEffectivePhoneNumber();
    final success = await ref
        .read(authNotifierProvider.notifier)
        .verifyOtp(phone, otp);

    if (success && mounted) {
      final updatedState = ref.read(authNotifierProvider);
      if (widget.onVerified != null) {
        widget.onVerified!({
          'phone': phone,
          'isNewUser': updatedState.isNewUser,
          'userData': updatedState.userData,
        });
        return;
      }

      try {
        GoRouter.of(context).go(RouteNames.profileSetup);
      } catch (_) {
        // Safe fallback for testing environments without GoRouter
      }
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    if (widget.onResendRequested != null) {
      widget.onResendRequested!();
      _startCountdown();
      return;
    }

    final phone = _getEffectivePhoneNumber();
    final success = await ref
        .read(authNotifierProvider.notifier)
        .resendOtp(phone);

    if (success && mounted) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully to your mobile number'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Preserved back navigation method for navigation infrastructure and testing.
  @visibleForTesting
  void handleBack() {
    final phone = _getEffectivePhoneNumber();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(phone);
    } else {
      try {
        GoRouter.of(context).go(
          RouteNames.mobileNumber,
          extra: {'phone': phone},
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authNotifierProvider);
    final isVerifying = authState.isVerifying;
    final errorMessage = _clientValidationError ?? authState.errorMessage;
    final hasError = errorMessage != null;

    final maxContentWidth = math.min(context.screenWidth - (AppSpacing.lg * 2), AppBreakpoints.maxFormWidth);
    final currentOtpText = _otpController.text;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Prevent system back actions from returning to previous screen.
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // -----------------------------------------------------------------
              // 1. TOP APP BAR (Centered Logo, Back Button Removed)
              // -----------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Center(
                  child: SizedBox(
                    width: maxContentWidth,
                    height: 44.0,
                    child: Center(
                      child: Image.asset(
                        VerifyOtpScreen.logoAssetPath,
                        height: context.r(44),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

            // -----------------------------------------------------------------
            // 2. MAIN SCROLLABLE CONTENT
            // -----------------------------------------------------------------
            Expanded(
              child: GestureDetector(
                onTap: () => _otpFocusNode.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.lg,
                            right: AppSpacing.lg,
                            top: 0.0,
                            bottom: AppSpacing.xs,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: maxContentWidth,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: AppSpacing.xs),

                                      // Heading: "Verify your\nmobile number"
                                      Text(
                                        'Verify your\nmobile number',
                                        style: AppTextStyles.headlineMedium.copyWith(
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: context.sp(26),
                                          height: 1.2,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),

                                      // Subtitle: "We sent a 4-digit code to"
                                      Text(
                                        'We sent a 4-digit code to',
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),

                                      // Phone number display chip with edit button (Pen icon)
                                      InkWell(
                                        key: const Key('edit_mobile_number_pill'),
                                        onTap: () {
                                          if (widget.onEditPhoneRequested != null) {
                                            widget.onEditPhoneRequested!();
                                          } else {
                                            handleBack();
                                          }
                                        },
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 6.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.surfaceDark
                                                : AppColors.surface,
                                            borderRadius:
                                                BorderRadius.circular(24.0),
                                            border: Border.all(
                                              color: isDark
                                                  ? AppColors.cardBorderDark
                                                  : const Color(0xFFE2E8F0),
                                              width: 1.0,
                                            ),
                                            boxShadow: isDark
                                                ? AppShadows.none
                                                : [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.03),
                                                      blurRadius: 6.0,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _getFormattedDisplayPhone(),
                                                  style: AppTextStyles.titleMedium.copyWith(
                                                    color: isDark
                                                        ? AppColors
                                                            .textPrimaryDark
                                                        : const Color(0xFF1E293B),
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.6,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Container(
                                                padding: const EdgeInsets.all(4.0),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? AppColors.surfaceContainerDark
                                                      : AppColors.secondary.withValues(alpha: 0.45),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.edit_rounded,
                                                  key: const Key('edit_mobile_number_icon'),
                                                  size: 16.0,
                                                  color: isDark
                                                      ? AppColors.textPrimaryDark
                                                      : AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppSpacing.lg,
                                      ),

                                      // ---------------------------------------
                                      // 3. 6-DIGIT OTP INPUT BOXES
                                      // ---------------------------------------
                                      Stack(
                                        children: [
                                          // Responsive 6-box row
                                          Row(
                                            children: List.generate(
                                              _otpLength,
                                              (index) => Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 4.0,
                                                  ),
                                                  child: _buildOtpBox(
                                                    index: index,
                                                    currentLength:
                                                        currentOtpText.length,
                                                    digits: currentOtpText,
                                                    hasError: hasError,
                                                    isDark: isDark,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Transparent underlying TextField for smooth native keyboard & paste
                                          Positioned.fill(
                                            child: Opacity(
                                              opacity: 0.0,
                                              child: TextField(
                                                controller: _otpController,
                                                focusNode: _otpFocusNode,
                                                keyboardType:
                                                    TextInputType.number,
                                                textInputAction:
                                                    TextInputAction.done,
                                                onSubmitted: (_) =>
                                                    _handleVerify(),
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                  LengthLimitingTextInputFormatter(
                                                      _otpLength),
                                                ],
                                                autofocus: true,
                                                enableInteractiveSelection:
                                                    true,
                                                showCursor: false,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Error Message / Helper Row
                                      if (hasError) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              size: 16.0,
                                              color: AppColors.error,
                                            ),
                                            const SizedBox(width: 6.0),
                                            Expanded(
                                              child: Text(
                                                errorMessage,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color: AppColors.error,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      const SizedBox(height: AppSpacing.lg),

                                      // ---------------------------------------
                                      // 4. RESEND OTP COUNTDOWN & RESEND LINK
                                      // ---------------------------------------
                                      Center(
                                        child: Column(
                                          children: [
                                            // Countdown pill
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.md,
                                                vertical: 7.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppColors.surfaceContainerDark
                                                    : AppColors.surface,
                                                borderRadius: BorderRadius.circular(20.0),
                                                border: Border.all(
                                                  color: isDark
                                                      ? AppColors.cardBorderDark
                                                      : const Color(0xFFE2E8F0),
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 15.0,
                                                    color: isDark
                                                        ? AppColors.textSecondaryDark
                                                        : const Color(0xFF64748B),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Flexible(
                                                    child: Text.rich(
                                                      TextSpan(
                                                        text: 'Resend OTP in ',
                                                        style: AppTextStyles.bodySmall.copyWith(
                                                          color: isDark
                                                              ? AppColors.textSecondaryDark
                                                              : const Color(0xFF64748B),
                                                          fontSize: 12.0,
                                                        ),
                                                        children: [
                                                          TextSpan(
                                                            text: '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                                            style: TextStyle(
                                                              color: isDark
                                                                  ? AppColors.textPrimaryDark
                                                                  : const Color(0xFF1E293B),
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: AppSpacing.xs),

                                            // Resend SMS text button
                                            InkWell(
                                              onTap: _canResend ? _handleResend : null,
                                              borderRadius: BorderRadius.circular(8.0),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10.0,
                                                  vertical: 6.0,
                                                ),
                                                child: Text(
                                                  "Didn't receive code? Resend SMS",
                                                  style: AppTextStyles.bodySmall.copyWith(
                                                    color: _canResend
                                                        ? AppColors.primary
                                                        : (isDark
                                                            ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                                                            : const Color(0xFF94A3B8)),
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12.5,
                                                    decoration: _canResend
                                                        ? TextDecoration.underline
                                                        : TextDecoration.none,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: AppSpacing.md),

                                      // ---------------------------------------
                                      // 5. SECURITY & TRUST BADGES
                                      // ---------------------------------------
                                      Center(
                                        child: Column(
                                          children: [
                                            // Security lock text
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.lock_outline_rounded,
                                                  size: 15.0,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 5.0),
                                                Flexible(
                                                  child: Text(
                                                    'Your verification code is valid for 10 minutes',
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: isDark
                                                          ? AppColors.textSecondaryDark
                                                          : const Color(0xFF64748B),
                                                      fontSize: 12.0,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: AppSpacing.sm),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // -------------------------------------------
                                  // 6. BOTTOM CTA BUTTON
                                  // -------------------------------------------
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: AppSpacing.md),
                                      Container(
                                        width: double.infinity,
                                        height: 54.0,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(27.0),
                                          boxShadow: currentOtpText.length ==
                                                      _otpLength &&
                                                  !isVerifying &&
                                                  !isDark
                                              ? AppShadows.primary
                                              : AppShadows.none,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: isVerifying ||
                                                  currentOtpText.length !=
                                                      _otpLength
                                              ? null
                                              : _handleVerify,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                currentOtpText.length ==
                                                        _otpLength
                                                    ? AppColors.primary
                                                    : (isDark
                                                        ? AppColors
                                                            .surfaceContainerDark
                                                        : const Color(
                                                            0xFF7D9E98)),
                                            foregroundColor:
                                                AppColors.onPrimary,
                                            disabledBackgroundColor: isDark
                                                ? AppColors
                                                    .surfaceContainerDark
                                                : const Color(0xFF7D9E98),
                                            disabledForegroundColor: Colors
                                                .white
                                                .withValues(alpha: 0.8),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(27.0),
                                            ),
                                            padding: const EdgeInsets
                                                .symmetric(
                                              horizontal: AppSpacing.xl,
                                            ),
                                          ),
                                          child: isVerifying
                                              ? const SizedBox(
                                                  width: 22.0,
                                                  height: 22.0,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      Colors.white,
                                                    ),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        'Verify & Continue',
                                                        style: AppTextStyles
                                                            .button
                                                            .copyWith(
                                                          fontSize: 16.0,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing: 0.2,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8.0),
                                                    const Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 20.0,
                                                      color: Colors.white,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildOtpBox({
    required int index,
    required int currentLength,
    required String digits,
    required bool hasError,
    required bool isDark,
  }) {
    final isFocused = index == currentLength && _otpFocusNode.hasFocus;
    final isFilled = index < currentLength;
    final digit = isFilled ? digits[index] : '';

    Color borderColor;
    if (hasError) {
      borderColor = AppColors.error;
    } else if (isFocused) {
      borderColor = const Color(0xFF2563EB); // Vibrant active indicator
    } else if (isFilled) {
      borderColor = AppColors.primary;
    } else {
      borderColor = isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 58.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: borderColor,
          width: isFocused ? 2.0 : 1.2,
        ),
        boxShadow: isFocused && !isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  blurRadius: 10.0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: isFilled
          ? Text(
              digit,
              style: AppTextStyles.headlineSmall.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            )
          : (isFocused
              ? FadeTransition(
                  opacity: _cursorAnimationController,
                  child: Container(
                    width: 2.0,
                    height: 24.0,
                    color: const Color(0xFF2563EB),
                  ),
                )
              : Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.textSecondaryDark.withValues(alpha: 0.4)
                        : const Color(0xFFCBD5E1),
                  ),
                )),
    );
  }
}
