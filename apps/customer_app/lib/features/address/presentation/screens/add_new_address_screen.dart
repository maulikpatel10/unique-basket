import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../profile_setup/presentation/providers/customer_profile_provider.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../providers/customer_address_provider.dart';

/// Supported address types for Screen 30.
enum AddressTypeOption {
  home('Home', Icons.home_rounded),
  office('Office', Icons.work_outline_rounded),
  other('Other', Icons.location_on_outlined);

  final String label;
  final IconData icon;
  const AddressTypeOption(this.label, this.icon);
}

/// Screen 30 — Add New Address for UNIQUE BASKET Customer App.
///
/// Implements the approved design reference:
/// `design/customer_app/screens/address/add_new_address/30_Add_New_Address.png`
/// - Top AppHeader with green background, back arrow, and title "Add New Address"
/// - Card 1: Contact Details (Full Name, Phone Number with +91)
/// - Card 2: Address Details (Building, Street/Area, Landmark, City, State, PIN Code with "✓ Deliverable" badge)
/// - Card 3: Save Address As (Home, Office, Other segmented cards)
/// - Card 4: Default Delivery Address Checkbox with "DEFAULT" badge
/// - Primary "✓ Save Address" CTA button
class AddNewAddressScreen extends ConsumerStatefulWidget {
  /// Fixed city for the initial delivery launch.
  static const String defaultCity = 'Rajkot';

  /// Fixed state for the initial delivery launch.
  static const String defaultState = 'Gujarat';

  /// Optional callback invoked upon successful address submission for testing.
  final ValueChanged<Map<String, dynamic>>? onAddressSaved;

  const AddNewAddressScreen({
    super.key,
    this.onAddressSaved,
  });

  @override
  ConsumerState<AddNewAddressScreen> createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends ConsumerState<AddNewAddressScreen> {
  AddressTypeOption _selectedAddressType = AddressTypeOption.home;
  bool _isDefaultAddress = false;
  bool _isSubmitting = false;

  // Form controllers
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _buildingController = TextEditingController();
  final _streetAreaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pinCodeController = TextEditingController();

  // Focus nodes
  final _fullNameFocusNode = FocusNode();
  final _phoneNumberFocusNode = FocusNode();
  final _buildingFocusNode = FocusNode();
  final _streetAreaFocusNode = FocusNode();
  final _landmarkFocusNode = FocusNode();
  final _pinCodeFocusNode = FocusNode();

  // Field focus states
  bool _isFullNameFocused = false;
  bool _isPhoneNumberFocused = false;
  bool _isBuildingFocused = false;
  bool _isStreetAreaFocused = false;
  bool _isLandmarkFocused = false;
  bool _isPinCodeFocused = false;

  // Validation error states
  String? _fullNameError;
  String? _phoneNumberError;
  String? _buildingError;
  String? _streetAreaError;
  String? _pinCodeError;

  bool _initializedProfile = false;

  @override
  void initState() {
    super.initState();
    _fullNameFocusNode.addListener(_handleFocusChanges);
    _phoneNumberFocusNode.addListener(_handleFocusChanges);
    _buildingFocusNode.addListener(_handleFocusChanges);
    _streetAreaFocusNode.addListener(_handleFocusChanges);
    _landmarkFocusNode.addListener(_handleFocusChanges);
    _pinCodeFocusNode.addListener(_handleFocusChanges);

    _pinCodeController.addListener(_handlePinCodeChange);
  }

  void _handleFocusChanges() {
    if (!mounted) return;
    setState(() {
      _isFullNameFocused = _fullNameFocusNode.hasFocus;
      _isPhoneNumberFocused = _phoneNumberFocusNode.hasFocus;
      _isBuildingFocused = _buildingFocusNode.hasFocus;
      _isStreetAreaFocused = _streetAreaFocusNode.hasFocus;
      _isLandmarkFocused = _landmarkFocusNode.hasFocus;
      _isPinCodeFocused = _pinCodeFocusNode.hasFocus;
    });
  }

  void _handlePinCodeChange() {
    if (!mounted) return;
    if (_pinCodeError != null) {
      setState(() {
        _pinCodeError = null;
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _fullNameFocusNode.removeListener(_handleFocusChanges);
    _phoneNumberFocusNode.removeListener(_handleFocusChanges);
    _buildingFocusNode.removeListener(_handleFocusChanges);
    _streetAreaFocusNode.removeListener(_handleFocusChanges);
    _landmarkFocusNode.removeListener(_handleFocusChanges);
    _pinCodeFocusNode.removeListener(_handleFocusChanges);

    _pinCodeController.removeListener(_handlePinCodeChange);

    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _buildingController.dispose();
    _streetAreaController.dispose();
    _landmarkController.dispose();
    _pinCodeController.dispose();

    _fullNameFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    _buildingFocusNode.dispose();
    _streetAreaFocusNode.dispose();
    _landmarkFocusNode.dispose();
    _pinCodeFocusNode.dispose();
    super.dispose();
  }

  bool get _isPinCodeDeliverable {
    final pin = _pinCodeController.text.trim();
    if (pin.length != 6) return false;
    final activePincodes = ref.watch(activeSupportedPincodesProvider).valueOrNull;
    if (activePincodes != null && activePincodes.isNotEmpty) {
      return activePincodes.contains(pin);
    }
    return false;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final fullName = _fullNameController.text.trim();
    final phone = _phoneNumberController.text.trim();
    final building = _buildingController.text.trim();
    final streetArea = _streetAreaController.text.trim();
    final landmark = _landmarkController.text.trim();
    final pinCode = _pinCodeController.text.trim();

    final activePincodes = ref.read(activeSupportedPincodesProvider).valueOrNull;
    final isPincodeServiceable = activePincodes == null ||
        activePincodes.isEmpty ||
        activePincodes.contains(pinCode);

    // Client-side validation
    String? fullNameError;
    if (fullName.isEmpty) {
      fullNameError = 'Full name is required';
    } else if (fullName.length < 2) {
      fullNameError = 'Enter a valid full name';
    }

    String? phoneError;
    if (phone.isEmpty) {
      phoneError = 'Phone number is required';
    } else if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      phoneError = 'Enter valid 10-digit mobile number';
    }

    String? buildingError;
    if (building.isEmpty) {
      buildingError = 'House / Flat / Floor / Building is required';
    } else if (building.length < 2) {
      buildingError = 'Building information must be at least 2 characters';
    }

    String? streetAreaError;
    if (streetArea.isEmpty) {
      streetAreaError = 'Apartment / Road / Area / Street is required';
    } else if (streetArea.length < 3) {
      streetAreaError = 'Street / Area must be at least 3 characters';
    }

    String? pinCodeError;
    if (pinCode.isEmpty) {
      pinCodeError = 'PIN Code is required';
    } else if (pinCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pinCode)) {
      pinCodeError = 'PIN Code must be 6 digits';
    } else if (!isPincodeServiceable) {
      pinCodeError = 'Delivery is currently not available for this pincode';
    }

    if (fullNameError != null ||
        phoneError != null ||
        buildingError != null ||
        streetAreaError != null ||
        pinCodeError != null) {
      setState(() {
        _fullNameError = fullNameError;
        _phoneNumberError = phoneError;
        _buildingError = buildingError;
        _streetAreaError = streetAreaError;
        _pinCodeError = pinCodeError;
      });

      if (fullNameError != null) {
        _fullNameFocusNode.requestFocus();
      } else if (phoneError != null) {
        _phoneNumberFocusNode.requestFocus();
      } else if (buildingError != null) {
        _buildingFocusNode.requestFocus();
      } else if (streetAreaError != null) {
        _streetAreaFocusNode.requestFocus();
      } else if (pinCodeError != null) {
        _pinCodeFocusNode.requestFocus();
      }
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _fullNameError = null;
      _phoneNumberError = null;
      _buildingError = null;
      _streetAreaError = null;
      _pinCodeError = null;
    });

    // Deterministic addressLine construction: "Building, StreetArea[, Landmark]"
    final combinedAddressLine = landmark.isNotEmpty
        ? (RegExp(r'^(near|opp|opposite|behind|beside)\s+', caseSensitive: false).hasMatch(landmark)
            ? '$building, $streetArea, $landmark'
            : '$building, $streetArea, Near $landmark')
        : '$building, $streetArea';

    final payload = {
      'title': _selectedAddressType.label,
      'addressLine': combinedAddressLine,
      'city': AddNewAddressScreen.defaultCity,
      'state': AddNewAddressScreen.defaultState,
      'pincode': pinCode,
      'isDefault': _isDefaultAddress,
    };

    try {
      final addressRepo = ref.read(customerAddressRepositoryProvider);
      await addressRepo.addAddress(
        title: _selectedAddressType.label,
        addressLine: combinedAddressLine,
        city: AddNewAddressScreen.defaultCity,
        state: AddNewAddressScreen.defaultState,
        pincode: pinCode,
        isDefault: _isDefaultAddress,
      );
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('PINCODE_NOT_SERVICEABLE') || errStr.contains('pincode')) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _pinCodeError = 'Delivery is currently not available for this pincode';
          });
          _pinCodeFocusNode.requestFocus();
        }
        return;
      }
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      // Invalidate address & dependent store providers
      ref.invalidate(customerAddressesProvider);
      ref.invalidate(defaultCustomerAddressProvider);
      ref.invalidate(servingStoreProvider);
      ref.invalidate(nearbyStoresProvider);

      // Update local storage if marked default for offline resilience
      if (_isDefaultAddress) {
        try {
          final localStorage = ref.read(localStorageProvider);
          await localStorage.setJson(AppConstants.keyUserAddress, {
            'type': _selectedAddressType.label,
            'fullAddress': building,
            'areaLocality': streetArea,
            'city': AddNewAddressScreen.defaultCity,
            'state': AddNewAddressScreen.defaultState,
            'pinCode': pinCode,
            if (landmark.isNotEmpty) 'landmark': landmark,
          });
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (widget.onAddressSaved != null) {
        widget.onAddressSaved!(payload);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address added successfully'),
          duration: Duration(milliseconds: 1500),
          backgroundColor: Color(0xFF014D40),
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        try {
          GoRouter.of(context).pop();
        } catch (_) {
          GoRouter.of(context).go(RouteNames.myAddresses);
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save address: $error'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        GoRouter.of(context).pop();
      } catch (_) {
        GoRouter.of(context).go(RouteNames.myAddresses);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activeSupportedPincodesProvider);
    ref.listen<AsyncValue<Map<String, dynamic>?>>(customerProfileProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user != null) {
        final name = user['name'] as String?;
        final phone = user['phone'] as String?;
        if (name != null && name.isNotEmpty && _fullNameController.text.isEmpty) {
          _fullNameController.text = name;
        }
        if (phone != null && phone.isNotEmpty && _phoneNumberController.text.isEmpty) {
          final cleanPhone = phone.replaceAll('+91', '').replaceAll(RegExp(r'\D'), '');
          _phoneNumberController.text = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
        }
      }
    });

    final currentUser = ref.watch(customerProfileProvider).valueOrNull;
    if (currentUser != null && !_initializedProfile) {
      _initializedProfile = true;
      final name = currentUser['name'] as String?;
      final phone = currentUser['phone'] as String?;
      if (name != null && name.isNotEmpty && _fullNameController.text.isEmpty) {
        _fullNameController.text = name;
      }
      if (phone != null && phone.isNotEmpty && _phoneNumberController.text.isEmpty) {
        final cleanPhone = phone.replaceAll('+91', '').replaceAll(RegExp(r'\D'), '');
        _phoneNumberController.text = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
      }
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppHeader(
        title: 'Add New Address',
        showBackButton: true,
        centerTitle: false,
        backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
        foregroundColor: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22.0),
          bottomRight: Radius.circular(22.0),
        ),
        onBackTap: _handleBack,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              MediaQuery.of(context).padding.bottom + 36.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxFormWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---------------------------------------------------
                    // SECTION 1: CONTACT DETAILS (Open Layout)
                    // ---------------------------------------------------
                    _buildSectionHeader(
                      icon: Icons.person_outline_rounded,
                      title: 'CONTACT DETAILS',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14.0),

                    // Full Name *
                    _buildFieldLabel(label: 'Full Name *', isDark: isDark),
                    const SizedBox(height: 6.0),
                    _buildTextInput(
                      controller: _fullNameController,
                      focusNode: _fullNameFocusNode,
                      isFocused: _isFullNameFocused,
                      hasError: _fullNameError != null,
                      hintText: 'Enter your full name',
                      isDark: isDark,
                      textCapitalization: TextCapitalization.words,
                      trailingWidget: _fullNameController.text.trim().isNotEmpty
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Color(0xFF64748B),
                            )
                          : null,
                    ),
                    if (_fullNameError != null)
                      _buildErrorText(_fullNameError!),

                    const SizedBox(height: 16.0),

                    // Phone Number *
                    _buildFieldLabel(label: 'Phone Number *', isDark: isDark),
                    const SizedBox(height: 6.0),
                    _buildPhoneInput(isDark: isDark),
                    if (_phoneNumberError != null)
                      _buildErrorText(_phoneNumberError!),

                    const SizedBox(height: 24.0),

                    // ---------------------------------------------------
                    // SECTION 2: ADDRESS DETAILS (Open Layout)
                    // ---------------------------------------------------
                    _buildSectionHeader(
                      icon: Icons.home_outlined,
                      title: 'ADDRESS DETAILS',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14.0),

                    // House / Flat / Floor / Building *
                    _buildFieldLabel(
                      label: 'House / Flat / Floor / Building *',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6.0),
                    _buildTextInput(
                      controller: _buildingController,
                      focusNode: _buildingFocusNode,
                      isFocused: _isBuildingFocused,
                      hasError: _buildingError != null,
                      hintText: '123, Green Heights',
                      isDark: isDark,
                      textCapitalization: TextCapitalization.words,
                    ),
                    if (_buildingError != null)
                      _buildErrorText(_buildingError!),

                    const SizedBox(height: 16.0),

                    // Apartment / Road / Area / Street *
                    _buildFieldLabel(
                      label: 'Apartment / Road / Area / Street *',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6.0),
                    _buildTextInput(
                      controller: _streetAreaController,
                      focusNode: _streetAreaFocusNode,
                      isFocused: _isStreetAreaFocused,
                      hasError: _streetAreaError != null,
                      hintText: 'Opp. Central Park, Example Road',
                      isDark: isDark,
                      textCapitalization: TextCapitalization.words,
                    ),
                    if (_streetAreaError != null)
                      _buildErrorText(_streetAreaError!),

                    const SizedBox(height: 16.0),

                    // Landmark (Optional)
                    _buildFieldLabel(
                      label: 'Landmark (Optional)',
                      isDark: isDark,
                      isOptional: true,
                    ),
                    const SizedBox(height: 6.0),
                    _buildTextInput(
                      controller: _landmarkController,
                      focusNode: _landmarkFocusNode,
                      isFocused: _isLandmarkFocused,
                      hasError: false,
                      hintText: 'e.g. Near Shivalik Lake or City Water Tank',
                      isDark: isDark,
                      textCapitalization: TextCapitalization.words,
                    ),

                    const SizedBox(height: 16.0),

                    // City * & State *
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(label: 'City *', isDark: isDark),
                              const SizedBox(height: 6.0),
                              _buildReadOnlyBox(
                                value: AddNewAddressScreen.defaultCity,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(label: 'State *', isDark: isDark),
                              const SizedBox(height: 6.0),
                              _buildReadOnlyBox(
                                value: AddNewAddressScreen.defaultState,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16.0),

                    // PIN Code *
                    _buildFieldLabel(label: 'PIN Code *', isDark: isDark),
                    const SizedBox(height: 6.0),
                    _buildPinCodeInput(isDark: isDark),
                    if (_pinCodeError != null)
                      _buildErrorText(_pinCodeError!),

                    // Subtle Section Divider
                    _buildSectionDivider(isDark),

                    // ---------------------------------------------------
                    // SECTION 3: SAVE ADDRESS AS (Open Pills)
                    // ---------------------------------------------------
                    _buildSectionHeader(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'SAVE ADDRESS AS',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14.0),
                    Row(
                      children: AddressTypeOption.values.map((type) {
                        final isSelected = _selectedAddressType == type;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: type != AddressTypeOption.other
                                  ? 6.0
                                  : 0.0,
                            ),
                            child: _buildAddressTypeOptionCard(
                              type: type,
                              isSelected: isSelected,
                              isDark: isDark,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Subtle Section Divider
                    _buildSectionDivider(isDark),

                    // ---------------------------------------------------
                    // SECTION 4: DEFAULT DELIVERY ADDRESS (Open Row)
                    // ---------------------------------------------------
                    _buildDefaultAddressRow(isDark),

                    const SizedBox(height: 24.0),

                    // ---------------------------------------------------
                    // SECTION 5: SAVE ADDRESS CTA
                    // ---------------------------------------------------
                    AppButton(
                      label: 'Save Address',
                      icon: Icons.check_rounded,
                      variant: ButtonVariant.primary,
                      size: ButtonSize.large,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _handleSubmit,
                    ),

                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildSectionDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Divider(
        height: 1.0,
        thickness: 0.8,
        color: isDark ? AppColors.dividerDark : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF00382E) : const Color(0xFFE7F5F4),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 15.0,
            color: isDark ? const Color(0xFF34D399) : const Color(0xFF014D40),
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 12.0,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAddressRow(bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _isDefaultAddress = !_isDefaultAddress;
        });
      },
      borderRadius: BorderRadius.circular(10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            // Custom Checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _isDefaultAddress
                    ? const Color(0xFF014D40)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isDefaultAddress
                      ? const Color(0xFF014D40)
                      : (isDark
                          ? AppColors.cardBorderDark
                          : const Color(0xFF94A3B8)),
                  width: 1.8,
                ),
              ),
              child: _isDefaultAddress
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Make this my default delivery address',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 2.5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC8E6C9),
                  width: 1,
                ),
              ),
              child: Text(
                'DEFAULT',
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w800,
                  fontSize: 10.0,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel({
    required String label,
    required bool isDark,
    bool isOptional = false,
  }) {
    final hasAsterisk = label.endsWith(' *') || label.endsWith('*');
    final cleanLabel = hasAsterisk
        ? (label.endsWith(' *')
            ? label.substring(0, label.length - 2)
            : label.substring(0, label.length - 1))
        : label;

    final baseStyle = AppTextStyles.labelMedium.copyWith(
      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
      fontWeight: FontWeight.w500,
      fontSize: 13.0,
    );

    if (hasAsterisk) {
      return Text.rich(
        TextSpan(
          text: cleanLabel,
          style: baseStyle,
          children: [
            TextSpan(
              text: ' *',
              style: baseStyle.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      label,
      style: baseStyle,
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required bool hasError,
    required String hintText,
    required bool isDark,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? trailingWidget,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 54.0,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: hasError
              ? AppColors.error
              : (isFocused
                  ? const Color(0xFF014D40)
                  : (isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0))),
          width: isFocused ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: textCapitalization,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                  fontSize: 14.0,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: false,
                  fillColor: Colors.transparent,
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
            if (trailingWidget != null) trailingWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput({required bool isDark}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 54.0,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _phoneNumberError != null
              ? AppColors.error
              : (_isPhoneNumberFocused
                  ? const Color(0xFF014D40)
                  : (isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0))),
          width: _isPhoneNumberFocused ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Country prefix
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇮🇳', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '+91',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1.0,
            height: 24.0,
            color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneNumberController,
              focusNode: _phoneNumberFocusNode,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 14.0,
              ),
              decoration: InputDecoration(
                hintText: '98765 43210',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                filled: false,
                fillColor: Colors.transparent,
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
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  Widget _buildReadOnlyBox({
    required String value,
    required bool isDark,
  }) {
    return Container(
      height: 54.0,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF475569),
          fontWeight: FontWeight.w600,
          fontSize: 14.0,
        ),
      ),
    );
  }

  Widget _buildPinCodeInput({required bool isDark}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 54.0,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _pinCodeError != null
              ? AppColors.error
              : (_isPinCodeFocused
                  ? const Color(0xFF014D40)
                  : (isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0))),
          width: _isPinCodeFocused ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pinCodeController,
                focusNode: _pinCodeFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                  fontSize: 14.0,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 360001',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: false,
                  fillColor: Colors.transparent,
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
            if (_isPinCodeDeliverable)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC8E6C9),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Deliverable',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
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

  Widget _buildAddressTypeOptionCard({
    required AddressTypeOption type,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAddressType = type;
        });
      },
      borderRadius: BorderRadius.circular(12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52.0,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF014D40)
              : (isDark ? AppColors.surfaceContainerDark : Colors.white),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF014D40)
                : (isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type.icon,
                size: 16.0,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6.0),
              Flexible(
                child: Text(
                  type.label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textPrimaryDark : const Color(0xFF334155)),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
      child: Text(
        error,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.error,
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
