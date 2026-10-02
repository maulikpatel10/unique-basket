import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../profile_setup/presentation/providers/customer_profile_provider.dart';

/// Screen 26 — Edit Profile for Unique Basket Customer App.
///
/// Reproduces the design reference `design/customer_app/screens/profile/edit_profile/26_Edit_Profile.png`:
/// - Pine green AppHeader with back navigation
/// - Centered avatar with camera badge and "Change Profile Photo" trigger
/// - Personal Information section with Full Name (editable) & Mobile Number (read-only + verified badge)
/// - Additional Information section with Date of Birth (date picker) & Gender (selector)
/// - Primary "SAVE CHANGES" CTA button with sync footer note
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  DateTime? _selectedDob;
  String? _selectedGender = 'Prefer not to say';
  String? _selectedPhotoPath;
  String? _clientValidationError;
  bool _isSubmitting = false;
  bool _initialized = false;
  String _initialPhone = '+91 98765 43210';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleNameChange);
  }

  void _handleNameChange() {
    if (_clientValidationError != null) {
      setState(() {
        _clientValidationError = null;
      });
    }
  }

  void _initializeFromProfile(Map<String, dynamic>? profile, String? localPhoto) {
    if (_initialized) return;
    _initialized = true;

    if (profile != null) {
      final name = (profile['name'] as String?)?.trim() ?? '';
      _nameController.text = name;

      final phone = (profile['phone'] as String?)?.trim();
      if (phone != null && phone.isNotEmpty) {
        _initialPhone = phone;
      }

      final dobStr = profile['dob'] as String?;
      if (dobStr != null && dobStr.isNotEmpty) {
        try {
          final parsed = DateTime.parse(dobStr).toUtc();
          _selectedDob = DateTime(parsed.year, parsed.month, parsed.day);
        } catch (_) {}
      }

      final gender = profile['gender'] as String?;
      if (gender != null && gender.isNotEmpty) {
        _selectedGender = gender;
      }
    }

    if (localPhoto != null && localPhoto.isNotEmpty) {
      _selectedPhotoPath = localPhoto;
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChange);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  String _formatDisplayPhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      final phone = digits.substring(2);
      return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return rawPhone;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'DD / MM / YYYY';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day / $month / $year';
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'UB';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedPhotoPath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to select photo. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPhotoActionSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.0,
                  height: 4.0,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardBorderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: context.sp(16.0),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  key: const Key('photo_option_camera'),
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFE8F8F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20.0),
                  ),
                  title: Text(
                    'Take Photo',
                    style: TextStyle(
                      fontSize: context.sp(14.0),
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  key: const Key('photo_option_gallery'),
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFE8F8F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 20.0),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontSize: context.sp(14.0),
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_selectedPhotoPath != null)
                  ListTile(
                    key: const Key('photo_option_remove'),
                    leading: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20.0),
                    ),
                    title: Text(
                      'Remove Photo',
                      style: TextStyle(
                        fontSize: context.sp(14.0),
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _selectedPhotoPath = null;
                      });
                    },
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDateOfBirth() async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstDate = DateTime(1920);
    final lastDate = DateTime(now.year - 10, now.month, now.day);
    final initialDate = _selectedDob ?? DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT DATE OF BIRTH',
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: theme.scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  void _showGenderSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final options = ['Prefer not to say', 'Male', 'Female', 'Other'];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.0,
                  height: 4.0,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardBorderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                Text(
                  'Select Gender',
                  style: TextStyle(
                    fontSize: context.sp(16.0),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...options.map((opt) {
                  final isSelected = opt == _selectedGender;
                  return ListTile(
                    title: Text(
                      opt,
                      style: TextStyle(
                        fontSize: context.sp(14.5),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A)),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20.0)
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _selectedGender = opt;
                      });
                    },
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final error = AppValidators.validateFullName(name);

    if (error != null) {
      setState(() {
        _clientValidationError = error;
      });
      _nameFocusNode.requestFocus();
      return;
    }

    if (name.length > 100) {
      setState(() {
        _clientValidationError = 'Name cannot exceed 100 characters';
      });
      _nameFocusNode.requestFocus();
      return;
    }

    _nameFocusNode.unfocus();

    setState(() {
      _isSubmitting = true;
      _clientValidationError = null;
    });

    final String? dobIso = _selectedDob != null
        ? DateTime.utc(
            _selectedDob!.year,
            _selectedDob!.month,
            _selectedDob!.day,
          ).toIso8601String()
        : null;

    try {
      // 1. Call Backend PUT /api/v1/customer/profile
      final repository = ref.read(customerProfileRepositoryProvider);
      await repository.updateProfile(
        name: name,
        dob: _selectedDob,
        gender: _selectedGender,
      );

      // 2. Update local storage cache
      final localStorage = ref.read(localStorageProvider);
      final existingData = localStorage.getJson(AppConstants.keyUserData) ?? {};
      final updatedData = {
        ...existingData,
        'name': name,
        'phone': _initialPhone,
        if (dobIso != null) 'dob': dobIso,
        if (_selectedPhotoPath != null) 'photoPath': _selectedPhotoPath,
        if (_selectedPhotoPath == null) 'photoPath': null,
        if (_selectedGender != null) 'gender': _selectedGender,
      };
      await localStorage.setJson(AppConstants.keyUserData, updatedData);
      if (dobIso != null) {
        await localStorage.setString(AppConstants.keyUserDob, dobIso);
      }

      // 3. Invalidate provider to trigger immediate refresh on Screen 25
      ref.invalidate(customerProfileProvider);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF014D40),
          duration: Duration(seconds: 2),
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        try {
          GoRouter.of(context).pop();
        } catch (_) {
          GoRouter.of(context).go(RouteNames.profile);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildAvatar(BuildContext context, bool isDark) {
    final hasValidLocalFile = _selectedPhotoPath != null &&
        File(_selectedPhotoPath!).existsSync();
    final initials = _getInitials(_nameController.text);

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _showPhotoActionSheet,
                child: Container(
                  width: context.r(88.0),
                  height: context.r(88.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : const Color(0xFFE7F5F4),
                    border: Border.all(
                      color: const Color(0xFF014D40).withValues(alpha: 0.2),
                      width: 2.0,
                    ),
                  ),
                  child: ClipOval(
                    child: hasValidLocalFile
                        ? Image.file(
                            File(_selectedPhotoPath!),
                            width: context.r(88.0),
                            height: context.r(88.0),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildInitials(initials),
                          )
                        : _buildInitials(initials),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _showPhotoActionSheet,
                  child: Container(
                    padding: const EdgeInsets.all(7.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF014D40),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.backgroundDark : Colors.white,
                        width: 2.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 14.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          GestureDetector(
            onTap: _showPhotoActionSheet,
            child: Text(
              'Change Profile Photo',
              style: TextStyle(
                fontSize: context.sp(14.0),
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.primaryUltraLight
                    : const Color(0xFF014D40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(String initials) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: context.sp(28.0),
          fontWeight: FontWeight.w800,
          color: const Color(0xFF014D40),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: context.sp(12.0),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: TextStyle(
              fontSize: context.sp(12.0),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
      ],
    );
  }

  Widget _buildPill(String text, {bool isVerified = false, bool isDark = false}) {
    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF06372A) : const Color(0xFFE8F8F5),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 13.0,
              color: Color(0xFF00796B),
            ),
            const SizedBox(width: 4.0),
            Text(
              text,
              style: TextStyle(
                fontSize: context.sp(11.5),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00796B),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.sp(11.5),
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildFullNameField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Full Name',
              style: TextStyle(
                fontSize: context.sp(13.5),
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4.0),
            const Text(
              '*',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00796B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        TextField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          textInputAction: TextInputAction.done,
          style: TextStyle(
            fontSize: context.sp(15.0),
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            errorText: _clientValidationError,
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.white,
            suffixIcon: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF94A3B8),
              size: 20.0,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: isDark ? AppColors.cardBorderDark : const Color(0xFFCBD5E1),
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: isDark ? AppColors.cardBorderDark : const Color(0xFFCBD5E1),
                width: 1.0,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'As registered for delivery and receipts',
          style: TextStyle(
            fontSize: context.sp(12.0),
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileNumberField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Mobile Number',
                style: TextStyle(
                  fontSize: context.sp(13.5),
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                ),
              ),
            ),
            _buildPill('Verified', isVerified: true, isDark: isDark),
          ],
        ),
        const SizedBox(height: 6.0),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _formatDisplayPhone(_initialPhone),
                  style: TextStyle(
                    fontSize: context.sp(15.0),
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textMutedDark : const Color(0xFF334155),
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF94A3B8),
                size: 20.0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 14.0,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: Text(
                'Primary account identifier. Cannot be edited directly.',
                style: TextStyle(
                  fontSize: context.sp(12.0),
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDobField(bool isDark) {
    final hasDob = _selectedDob != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Date of Birth',
                style: TextStyle(
                  fontSize: context.sp(13.5),
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                ),
              ),
            ),
            _buildPill('Optional', isVerified: false, isDark: isDark),
          ],
        ),
        const SizedBox(height: 6.0),
        GestureDetector(
          onTap: _selectDateOfBirth,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isDark ? AppColors.cardBorderDark : const Color(0xFFCBD5E1),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _formatDate(_selectedDob),
                    style: TextStyle(
                      fontSize: context.sp(15.0),
                      fontWeight: hasDob ? FontWeight.w600 : FontWeight.w500,
                      color: hasDob
                          ? (isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A))
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF94A3B8),
                  size: 20.0,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Receive exclusive birthday treats and anniversary offers',
          style: TextStyle(
            fontSize: context.sp(12.0),
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Gender',
                style: TextStyle(
                  fontSize: context.sp(13.5),
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                ),
              ),
            ),
            _buildPill('Optional', isVerified: false, isDark: isDark),
          ],
        ),
        const SizedBox(height: 6.0),
        GestureDetector(
          onTap: _showGenderSelector,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isDark ? AppColors.cardBorderDark : const Color(0xFFCBD5E1),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _selectedGender ?? 'Prefer not to say',
                    style: TextStyle(
                      fontSize: context.sp(15.0),
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF94A3B8),
                  size: 24.0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profileAsync = ref.watch(customerProfileProvider);
    final localStorage = ref.watch(localStorageProvider);
    final localUserData = localStorage.getJson(AppConstants.keyUserData);
    final localPhoto = localUserData?['photoPath'] as String?;

    profileAsync.whenData((profile) {
      _initializeFromProfile(profile, localPhoto);
    });

    if (!_initialized && localUserData != null) {
      _initializeFromProfile(localUserData, localPhoto);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
      appBar: AppHeader(
        title: 'Edit Profile',
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
            GoRouter.of(context).go(RouteNames.profile);
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: context.h(AppSpacing.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(context, isDark),
              const SizedBox(height: 24.0),

              // 1. Personal Information
              _buildSectionHeader('PERSONAL INFORMATION', trailing: 'Required fields *'),
              const SizedBox(height: 12.0),
              _buildFullNameField(isDark),
              const SizedBox(height: 16.0),
              _buildMobileNumberField(isDark),
              const SizedBox(height: 24.0),

              // 2. Additional Information
              _buildSectionHeader('ADDITIONAL INFORMATION'),
              const SizedBox(height: 12.0),
              _buildDobField(isDark),
              const SizedBox(height: 16.0),
              _buildGenderField(isDark),
              const SizedBox(height: 32.0),

              // 3. CTA Save Button
              AppButton(
                label: 'SAVE CHANGES',
                variant: ButtonVariant.primary,
                size: ButtonSize.large,
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
                borderRadius: BorderRadius.circular(999.0),
              ),
              const SizedBox(height: 12.0),

              // 4. Sync Note Footer
              Center(
                child: Text(
                  'Changes will sync across your Unique Basket orders and deliveries',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.sp(12.0),
                    color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
