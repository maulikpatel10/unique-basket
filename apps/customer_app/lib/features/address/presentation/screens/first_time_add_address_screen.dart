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
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/validators/app_validators.dart';
import '../providers/customer_address_provider.dart';

/// Enum representing the address type selection.
enum AddressType {
  home('Home', Icons.home_outlined),
  work('Work', Icons.work_outline_rounded),
  other('Other', Icons.location_on_outlined);

  final String label;
  final IconData icon;
  const AddressType(this.label, this.icon);
}

/// Screen 07 — First Time Add Address for Unique Basket Customer App.
///
/// Accurately reproduces the approved 07_First_Time_Add_Address design reference
/// and the Pincode error bottom sheet reference:
/// - Top bar: Circular Back button + Centered Logo + "STEP 4 OF 4" pill badge
/// - Bold left-aligned heading + subtitle
/// - Save Address As segmented option pills (Home, Work, Other)
/// - Full Address input with required indicator
/// - Area / Locality input with required indicator
/// - City (fixed: "Rajkot" — read-only) & State (fixed: "Gujarat" — read-only)
/// - PIN Code (6-digit numeric input with delivery area validation) & Landmark
/// - Delivery Note optional input
/// - Pincode error modal bottom sheet when non-deliverable pincode is entered
/// - Primary "Save & Continue →" CTA button
/// - Footer note about default delivery location
class FirstTimeAddAddressScreen extends ConsumerStatefulWidget {
  /// Logo asset path.
  static const String logoAssetPath = 'assets/logos/unique_basket_logo.png';

  /// Fixed city for the initial delivery launch.
  static const String defaultCity = 'Rajkot';

  /// Fixed state for the initial delivery launch.
  static const String defaultState = 'Gujarat';

  /// Allowed pincodes set in Rajkot city.
  static const Set<String> allowedPincodes = AppValidators.allowedPincodes;

  /// Optional callback invoked upon successful address submission for testing.
  final ValueChanged<Map<String, dynamic>>? onAddressSaved;

  const FirstTimeAddAddressScreen({
    super.key,
    this.onAddressSaved,
  });

  @override
  ConsumerState<FirstTimeAddAddressScreen> createState() =>
      _FirstTimeAddAddressScreenState();
}

class _FirstTimeAddAddressScreenState
    extends ConsumerState<FirstTimeAddAddressScreen> {
  AddressType _selectedAddressType = AddressType.home;

  final _fullAddressController = TextEditingController();
  final _areaLocalityController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _deliveryNoteController = TextEditingController();

  final _fullAddressFocusNode = FocusNode();
  final _areaLocalityFocusNode = FocusNode();
  final _pinCodeFocusNode = FocusNode();
  final _landmarkFocusNode = FocusNode();
  final _deliveryNoteFocusNode = FocusNode();

  bool _isFullAddressFocused = false;
  bool _isAreaLocalityFocused = false;
  bool _isPinCodeFocused = false;
  bool _isLandmarkFocused = false;
  bool _isDeliveryNoteFocused = false;

  String? _fullAddressError;
  String? _areaLocalityError;
  String? _pinCodeError;

  bool _isSubmitting = false;
  bool _isBottomSheetOpen = false;

  // Track last text to only clear errors on actual user keystrokes
  String _lastFullAddressText = '';
  String _lastAreaLocalityText = '';
  String _lastPinCodeText = '';

  @override
  void initState() {
    super.initState();
    _fullAddressFocusNode.addListener(_handleFocusChanges);
    _areaLocalityFocusNode.addListener(_handleFocusChanges);
    _pinCodeFocusNode.addListener(_handleFocusChanges);
    _landmarkFocusNode.addListener(_handleFocusChanges);
    _deliveryNoteFocusNode.addListener(_handleFocusChanges);

    _fullAddressController.addListener(_handleFullAddressChange);
    _areaLocalityController.addListener(_handleAreaLocalityChange);
    _pinCodeController.addListener(_handlePinCodeChange);
  }

  void _handleFocusChanges() {
    setState(() {
      _isFullAddressFocused = _fullAddressFocusNode.hasFocus;
      _isAreaLocalityFocused = _areaLocalityFocusNode.hasFocus;
      _isPinCodeFocused = _pinCodeFocusNode.hasFocus;
      _isLandmarkFocused = _landmarkFocusNode.hasFocus;
      _isDeliveryNoteFocused = _deliveryNoteFocusNode.hasFocus;
    });
  }

  void _handleFullAddressChange() {
    if (_fullAddressController.text != _lastFullAddressText) {
      _lastFullAddressText = _fullAddressController.text;
      if (_fullAddressError != null) {
        setState(() {
          _fullAddressError = null;
        });
      }
    }
  }

  void _handleAreaLocalityChange() {
    if (_areaLocalityController.text != _lastAreaLocalityText) {
      _lastAreaLocalityText = _areaLocalityController.text;
      if (_areaLocalityError != null) {
        setState(() {
          _areaLocalityError = null;
        });
      }
    }
  }

  void _handlePinCodeChange() {
    final currentText = _pinCodeController.text;
    if (currentText != _lastPinCodeText) {
      _lastPinCodeText = currentText;
      if (_pinCodeError != null) {
        setState(() {
          _pinCodeError = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullAddressFocusNode.removeListener(_handleFocusChanges);
    _areaLocalityFocusNode.removeListener(_handleFocusChanges);
    _pinCodeFocusNode.removeListener(_handleFocusChanges);
    _landmarkFocusNode.removeListener(_handleFocusChanges);
    _deliveryNoteFocusNode.removeListener(_handleFocusChanges);

    _fullAddressController.removeListener(_handleFullAddressChange);
    _areaLocalityController.removeListener(_handleAreaLocalityChange);
    _pinCodeController.removeListener(_handlePinCodeChange);

    _fullAddressController.dispose();
    _areaLocalityController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    _deliveryNoteController.dispose();

    _fullAddressFocusNode.dispose();
    _areaLocalityFocusNode.dispose();
    _pinCodeFocusNode.dispose();
    _landmarkFocusNode.dispose();
    _deliveryNoteFocusNode.dispose();
    super.dispose();
  }

  /// Displays the official Pincode Error Bottom Sheet matching `Pincode error.png`.
  Future<void> _showPincodeErrorBottomSheet(String invalidPincode) async {
    if (_isBottomSheetOpen) return;
    _isBottomSheetOpen = true;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Drag Handle
                Center(
                  child: Container(
                    width: 36.0,
                    height: 4.0,
                    margin: const EdgeInsets.only(top: 4.0, bottom: 20.0),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),

                // 2. Icon Container Badge (Circular mint background with location-off icon)
                Container(
                  width: 64.0,
                  height: 64.0,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.location_off_outlined,
                      size: 30.0,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Heading: "We're not delivering here yet"
                Text(
                  "We're not delivering here yet",
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                // 4. Description Text with bold dynamic PIN code
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text.rich(
                    TextSpan(
                      text:
                          'Sorry, UNIQUE BASKET is currently unavailable at PIN code ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF64748B),
                        height: 1.45,
                        fontSize: 13.5,
                      ),
                      children: [
                        TextSpan(
                          text: '$invalidPincode.',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.primary,
                          ),
                        ),
                        const TextSpan(
                          text:
                              " We're working to expand our delivery area. Please try another PIN code to continue.",
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 5. Primary Action: "Change PIN Code ✎"
                Container(
                  width: double.infinity,
                  height: 54.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27.0),
                    boxShadow: !isDark ? AppShadows.primary : AppShadows.none,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _pinCodeFocusNode.requestFocus();
                      _pinCodeController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _pinCodeController.text.length,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Change PIN Code',
                          style: AppTextStyles.button.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        const Icon(
                          Icons.edit_outlined,
                          size: 18.0,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 6. Secondary Action: "Enter a different address"
                TextButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _fullAddressFocusNode.requestFocus();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDark ? AppColors.primaryLight : AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.md,
                    ),
                  ),
                  child: Text(
                    'Enter a different address',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        );
      },
    );

    _isBottomSheetOpen = false;
  }

  Future<void> _handleSubmit() async {
    final fullAddress = _fullAddressController.text.trim();
    final areaLocality = _areaLocalityController.text.trim();
    final pinCode = _pinCodeController.text.trim();
    final landmark = _landmarkController.text.trim();
    final deliveryNote = _deliveryNoteController.text.trim();

    final fullAddressError = AppValidators.validateFullAddress(fullAddress);
    final areaLocalityError = AppValidators.validateAreaLocality(areaLocality);
    final pinCodeError = AppValidators.validatePinCode(pinCode);

    if (fullAddressError != null ||
        areaLocalityError != null ||
        pinCodeError != null) {
      setState(() {
        _fullAddressError = fullAddressError;
        _areaLocalityError = areaLocalityError;
        _pinCodeError = pinCodeError;
      });

      if (pinCode.length == 6 &&
          !FirstTimeAddAddressScreen.allowedPincodes.contains(pinCode)) {
        _pinCodeFocusNode.requestFocus();
        _showPincodeErrorBottomSheet(pinCode);
      } else if (fullAddressError != null) {
        _fullAddressFocusNode.requestFocus();
      } else if (areaLocalityError != null) {
        _areaLocalityFocusNode.requestFocus();
      } else if (pinCodeError != null) {
        _pinCodeFocusNode.requestFocus();
      }
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _fullAddressError = null;
      _areaLocalityError = null;
      _pinCodeError = null;
    });

    final addressPayload = {
      'type': _selectedAddressType.label,
      'fullAddress': fullAddress,
      'areaLocality': areaLocality,
      'city': FirstTimeAddAddressScreen.defaultCity,
      'state': FirstTimeAddAddressScreen.defaultState,
      'pinCode': pinCode,
      'landmark': landmark.isNotEmpty ? landmark : null,
      'deliveryNote': deliveryNote.isNotEmpty ? deliveryNote : null,
    };

    // Build combined addressLine from fullAddress + areaLocality (+ landmark if present)
    final combinedAddressLine = landmark.isNotEmpty
        ? '$fullAddress, $areaLocality, Near $landmark'
        : '$fullAddress, $areaLocality';

    // Persist address to Backend API (PostgreSQL user_addresses table)
    try {
      final addressRepo = ref.read(customerAddressRepositoryProvider);
      await addressRepo.addAddress(
        title: _selectedAddressType.label,
        addressLine: combinedAddressLine,
        city: FirstTimeAddAddressScreen.defaultCity,
        state: FirstTimeAddAddressScreen.defaultState,
        pincode: pinCode,
        isDefault: true,
      );
    } catch (_) {
      // Continue even if network error so user flow is not blocked if offline
    }

    // Persist address completion state and address payload
    try {
      final localStorage = ref.read(localStorageProvider);
      await localStorage.setJson(AppConstants.keyUserAddress, addressPayload);
      await localStorage.setBool(AppConstants.keyAddressCompleted, true);
    } catch (_) {}

    // Smooth transition simulation
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (widget.onAddressSaved != null) {
      widget.onAddressSaved!(addressPayload);
      return;
    }

    try {
      GoRouter.of(context).go(RouteNames.home);
    } catch (_) {
      try {
        GoRouter.of(context).go(RouteNames.placeholder);
      } catch (_) {}
    }
  }

  /// Preserved back navigation method for navigation infrastructure and testing.
  @visibleForTesting
  void handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        GoRouter.of(context).go(RouteNames.profileSetup);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Prevent system back actions from returning to previous setup screens.
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // -----------------------------------------------------------------
              // 1. TOP APP BAR (Centered Logo + Step 4 of 4 badge)
              // -----------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.xxs,
                  bottom: 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxFormWidth),
                    child: SizedBox(
                      height: 44.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Centered Brand Logo (Mathematically centered relative to screen width)
                          Center(
                            child: Image.asset(
                              FirstTimeAddAddressScreen.logoAssetPath,
                              height: context.r(44),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
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
                onTap: () => FocusScope.of(context).unfocus(),
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
                            top: 0,
                            bottom: AppSpacing.sm,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: AppBreakpoints.maxFormWidth),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Heading: "Add delivery address"
                                      Text(
                                        'Add delivery address',
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
                                      const SizedBox(height: AppSpacing.xs),

                                      // Subtitle
                                      Text(
                                        'Where should we deliver your fresh produce?',
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),

                                      // ---------------------------------------
                                      // 3. SAVE ADDRESS AS (Segmented Pills)
                                      // ---------------------------------------
                                      Text(
                                        'SAVE ADDRESS AS',
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : const Color(0xFF4A5568),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),

                                      Row(
                                        children: AddressType.values
                                            .map((type) => Expanded(
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                      right: type !=
                                                              AddressType.other
                                                          ? 8.0
                                                          : 0.0,
                                                    ),
                                                    child: _buildAddressTypePill(
                                                      type: type,
                                                      isSelected:
                                                          _selectedAddressType ==
                                                              type,
                                                      isDark: isDark,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),

                                      const SizedBox(height: AppSpacing.md),

                                      // ---------------------------------------
                                      // 4. FIELD 1: FULL ADDRESS * (Required)
                                      // ---------------------------------------
                                      _buildFieldHeader(
                                        label: 'FULL ADDRESS',
                                        isRequired: true,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      _buildInputField(
                                        controller: _fullAddressController,
                                        focusNode: _fullAddressFocusNode,
                                        isFocused: _isFullAddressFocused,
                                        hasError: _fullAddressError != null,
                                        hintText:
                                            'Flat 402, Green Meadows, 4th Main Road',
                                        prefixIcon: Icons.apartment_rounded,
                                        isDark: isDark,
                                        keyboardType:
                                            TextInputType.streetAddress,
                                        textCapitalization:
                                            TextCapitalization.words,
                                      ),
                                      if (_fullAddressError != null)
                                        _buildFieldError(_fullAddressError!),

                                      const SizedBox(height: AppSpacing.xs),

                                      // ---------------------------------------
                                      // 5. FIELD 2: AREA / LOCALITY * (Required)
                                      // ---------------------------------------
                                      _buildFieldHeader(
                                        label: 'AREA / LOCALITY',
                                        isRequired: true,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      _buildInputField(
                                        controller: _areaLocalityController,
                                        focusNode: _areaLocalityFocusNode,
                                        isFocused: _isAreaLocalityFocused,
                                        hasError: _areaLocalityError != null,
                                        hintText: 'Indiranagar Stage 2',
                                        prefixIcon: Icons.near_me_outlined,
                                        isDark: isDark,
                                        textCapitalization:
                                            TextCapitalization.words,
                                      ),
                                      if (_areaLocalityError != null)
                                        _buildFieldError(_areaLocalityError!),

                                      const SizedBox(height: AppSpacing.xs),

                                      // ---------------------------------------
                                      // 6. ROW: CITY (Fixed) & STATE (Fixed)
                                      // ---------------------------------------
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // CITY (Read-only: Rajkot)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildFieldHeader(
                                                  label: 'CITY',
                                                  isRequired: true,
                                                  isDark: isDark,
                                                ),
                                                const SizedBox(
                                                    height: AppSpacing.xs),
                                                _buildReadOnlyField(
                                                  value:
                                                      FirstTimeAddAddressScreen
                                                          .defaultCity,
                                                  prefixIcon: Icons
                                                      .location_city_rounded,
                                                  isDark: isDark,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),

                                          // STATE (Read-only: Gujarat)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildFieldHeader(
                                                  label: 'STATE',
                                                  isRequired: true,
                                                  isDark: isDark,
                                                ),
                                                const SizedBox(
                                                    height: AppSpacing.xs),
                                                _buildReadOnlyField(
                                                  value:
                                                      FirstTimeAddAddressScreen
                                                          .defaultState,
                                                  prefixIcon:
                                                      Icons.map_outlined,
                                                  isDark: isDark,
                                                  trailingIcon: Icons
                                                      .keyboard_arrow_down_rounded,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: AppSpacing.xs),

                                      // ---------------------------------------
                                      // 7. ROW: PIN CODE * & LANDMARK (Optional)
                                      // ---------------------------------------
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // PIN CODE (Required, 6 digits numeric)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildFieldHeader(
                                                  label: 'PIN CODE',
                                                  isRequired: true,
                                                  isDark: isDark,
                                                ),
                                                const SizedBox(
                                                    height: AppSpacing.xs),
                                                _buildInputField(
                                                  controller:
                                                      _pinCodeController,
                                                  focusNode:
                                                      _pinCodeFocusNode,
                                                  isFocused: _isPinCodeFocused,
                                                  hasError:
                                                      _pinCodeError != null,
                                                  hintText: '360005',
                                                  prefixIcon:
                                                      Icons.pin_drop_outlined,
                                                  isDark: isDark,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                    LengthLimitingTextInputFormatter(
                                                        6),
                                                  ],
                                                ),
                                                if (_pinCodeError != null)
                                                  _buildFieldError(
                                                      _pinCodeError!),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),

                                          // LANDMARK (Optional)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildFieldHeader(
                                                  label: 'LANDMARK',
                                                  isRequired: false,
                                                  isDark: isDark,
                                                ),
                                                const SizedBox(
                                                    height: AppSpacing.xs),
                                                _buildInputField(
                                                  controller:
                                                      _landmarkController,
                                                  focusNode:
                                                      _landmarkFocusNode,
                                                  isFocused:
                                                      _isLandmarkFocused,
                                                  hasError: false,
                                                  hintText: 'Near Nana Mova',
                                                  prefixIcon: Icons
                                                      .outlined_flag_rounded,
                                                  isDark: isDark,
                                                  textCapitalization:
                                                      TextCapitalization.words,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: AppSpacing.xs),

                                      // ---------------------------------------
                                      // 8. FIELD 5: DELIVERY NOTE (Optional)
                                      // ---------------------------------------
                                      _buildFieldHeader(
                                        label: 'DELIVERY NOTE',
                                        isRequired: false,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      _buildInputField(
                                        controller: _deliveryNoteController,
                                        focusNode: _deliveryNoteFocusNode,
                                        isFocused: _isDeliveryNoteFocused,
                                        hasError: false,
                                        hintText:
                                            'e.g. Leave at door, ring bell',
                                        prefixIcon: Icons.edit_note_rounded,
                                        isDark: isDark,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ],
                                  ),

                                  // -------------------------------------------
                                  // 9. BOTTOM CTA & FOOTER
                                  // -------------------------------------------
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: AppSpacing.md),

                                      // Primary "Save & Continue →" CTA
                                      Container(
                                        width: double.infinity,
                                        height: 54.0,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(27.0),
                                          boxShadow: !_isSubmitting && !isDark
                                              ? AppShadows.primary
                                              : AppShadows.none,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : _handleSubmit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: AppColors.onPrimary,
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.lg,
                                            ),
                                          ),
                                          child: _isSubmitting
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
                                                        'Save & Continue',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: AppTextStyles
                                                            .button
                                                            .copyWith(
                                                          fontSize: 16.0,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing: 0.2,
                                                        ),
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

                                      // Footer Note
                                      Text(
                                        'This address will be saved as your default delivery location.',
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                          fontSize: 12.0,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
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

  Widget _buildAddressTypePill({
    required AddressType type,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAddressType = type;
        });
      },
      borderRadius: BorderRadius.circular(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46.0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? AppColors.cardBorderDark
                    : const Color(0xFFE2E8F0)),
            width: 1.2,
          ),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : AppShadows.none,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 16.0,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF475569)),
            ),
            const SizedBox(width: 4.0),
            Flexible(
              child: Text(
                type.label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF475569)),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldHeader({
    required String label,
    required bool isRequired,
    required bool isDark,
  }) {
    return Text.rich(
      TextSpan(
        text: label,
        style: AppTextStyles.labelMedium.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : const Color(0xFF4A5568),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : null,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required bool hasError,
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 54.0,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: hasError
              ? AppColors.error
              : (isFocused
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.cardBorderDark
                      : const Color(0xFFE2E8F0))),
          width: isFocused ? 1.6 : 1.2,
        ),
        boxShadow: isDark
            ? AppShadows.none
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(
                      alpha: isFocused ? 0.08 : 0.02),
                  blurRadius: isFocused ? 10.0 : 6.0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            Icon(
              prefixIcon,
              size: 20.0,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: textCapitalization,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: AppTextStyles.titleMedium.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                    fontSize: 14.0,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a clean read-only field (used for fixed City and State).
  Widget _buildReadOnlyField({
    required String value,
    required IconData prefixIcon,
    required bool isDark,
    IconData? trailingIcon,
  }) {
    return Container(
      height: 54.0,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark
              ? AppColors.cardBorderDark
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            Icon(
              prefixIcon,
              size: 20.0,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingIcon != null)
              Icon(
                trailingIcon,
                size: 18.0,
                color: const Color(0xFF94A3B8),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldError(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 13.0,
            color: AppColors.error,
          ),
          const SizedBox(width: 4.0),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
