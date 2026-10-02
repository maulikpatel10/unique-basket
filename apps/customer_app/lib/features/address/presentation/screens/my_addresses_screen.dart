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
import '../../../profile_setup/presentation/providers/customer_profile_provider.dart';
import '../../../store/presentation/providers/store_provider.dart';
import '../providers/customer_address_provider.dart';

/// Screen 29 — My Addresses Screen matching 29_My_Addresses.png.
class MyAddressesScreen extends ConsumerStatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  ConsumerState<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends ConsumerState<MyAddressesScreen> {
  bool _isActionInProgress = false;

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
    ref.invalidate(customerAddressesProvider);
    await ref.read(customerAddressesProvider.future);
  }

  Future<void> _handleSetDefault(String addressId) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    HapticFeedback.selectionClick();

    try {
      final repository = ref.read(customerAddressRepositoryProvider);
      await repository.setDefaultAddress(addressId);

      // Invalidate address & dependent store providers
      ref.invalidate(customerAddressesProvider);
      ref.invalidate(servingStoreProvider);
      ref.invalidate(nearbyStoresProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default address updated'),
            duration: Duration(milliseconds: 900),
            backgroundColor: Color(0xFF014D40),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set default address: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  void _handleEditAddress(String addressId) {
    HapticFeedback.lightImpact();
    try {
      GoRouter.of(context).push(
        RouteNames.editAddress,
        extra: {'addressId': addressId},
      );
    } catch (_) {
      // Fallback
    }
  }

  void _handleAddNewAddress() {
    HapticFeedback.lightImpact();
    try {
      GoRouter.of(context).push(RouteNames.addNewAddress);
    } catch (_) {
      // Fallback
    }
  }

  Future<void> _confirmDeleteAddress(String addressId, String title) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Text(
          'Delete Address?',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$title"? This action cannot be undone.',
          style: TextStyle(
            fontSize: 14.0,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isActionInProgress = true);
      try {
        final repository = ref.read(customerAddressRepositoryProvider);
        await repository.deleteAddress(addressId);

        // Invalidate providers
        ref.invalidate(customerAddressesProvider);
        ref.invalidate(servingStoreProvider);
        ref.invalidate(nearbyStoresProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              duration: Duration(milliseconds: 900),
              backgroundColor: Color(0xFF014D40),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete address: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isActionInProgress = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final addressesAsync = ref.watch(customerAddressesProvider);
    final profileData = ref.watch(customerProfileProvider).valueOrNull;
    final userName = profileData?['name'] as String? ?? 'Maulik Patel';
    final userPhone = profileData?['phone'] as String? ?? '+91 98765 43210';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
      appBar: AppHeader(
        title: 'My Addresses',
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
        child: addressesAsync.when(
          loading: () => const Center(
            child: AppLoading(message: 'Loading saved addresses...'),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppErrorState(
                title: 'Unable to load addresses',
                message: 'We could not load your saved addresses. Please check your connection and try again.',
                retryText: 'Try Again',
                onRetry: () => ref.refresh(customerAddressesProvider),
              ),
            ),
          ),
          data: (addressesRaw) {
            final addresses = addressesRaw.whereType<Map<String, dynamic>>().toList();

            if (addresses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppEmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'No saved addresses',
                    message: 'You haven\'t added any delivery addresses yet. Add your address to start receiving fresh groceries.',
                    actionText: '+ Add New Address',
                    onAction: _handleAddNewAddress,
                  ),
                ),
              );
            }

            final count = addresses.length;

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF014D40),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: context.h(AppSpacing.md),
                ),
                children: [
                  // 1. Saved Locations Subheader Row
                  _buildSubheader(context, isDark, count),
                  const SizedBox(height: 16.0),

                  // 2. Address Cards List
                  ...addresses.map((address) {
                    final isDefault = address['isDefault'] == true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: _buildAddressCard(
                        context,
                        isDark,
                        address,
                        isDefault,
                        userName,
                        userPhone,
                      ),
                    );
                  }),
                  SizedBox(height: context.h(20.0)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubheader(BuildContext context, bool isDark, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAVED LOCATIONS',
                style: TextStyle(
                  fontSize: context.sp(11.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  fontFamily: AppTextStyles.fontFamily,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 3.0),
              Text(
                '$count ${count == 1 ? 'address' : 'addresses'} available',
                style: TextStyle(
                  fontSize: context.sp(14.5),
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyles.fontFamily,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        // + Add New Button Pill
        Material(
          color: isDark ? const Color(0xFF00695C) : const Color(0xFF014D40),
          borderRadius: BorderRadius.circular(999.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(999.0),
            onTap: _handleAddNewAddress,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    size: 16.0,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Add New',
                    style: TextStyle(
                      fontSize: context.sp(13.0),
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> address,
    bool isDefault,
    String defaultName,
    String defaultPhone,
  ) {
    final addressId = address['id'] as String? ?? '';
    final title = address['title'] as String? ?? 'Home';
    final addressLine = address['addressLine'] as String? ?? '';
    final city = address['city'] as String? ?? 'Rajkot';
    final state = address['state'] as String? ?? 'Gujarat';
    final pincode = address['pincode'] as String? ?? '';
    final name = address['recipientName'] as String? ?? defaultName;
    final phone = address['recipientPhone'] as String? ?? defaultPhone;

    final fullDisplayAddress = [
      if (addressLine.isNotEmpty) addressLine,
      if (city.isNotEmpty && state.isNotEmpty) '$city, $state $pincode'.trim(),
    ].join(', ');

    final isWork = title.toLowerCase().contains('work') || title.toLowerCase().contains('office');
    final isHomeOnly = title.toLowerCase().trim() == 'home';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDefault
              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF014D40))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isDefault ? 1.6 : 1.0,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6.0,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          if (!isDefault && addressId.isNotEmpty) {
            _handleSetDefault(addressId);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon + Title/Name + (Actions or Radio)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading Icon
                  if (isDefault) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.radio_button_checked,
                        size: 22.0,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF014D40),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 36.0,
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Icon(
                        isWork
                            ? Icons.work_outline_rounded
                            : isHomeOnly
                                ? Icons.home_outlined
                                : Icons.location_on_outlined,
                        size: 20.0,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF475569),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12.0),

                  // Middle: Title + Tag & Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: context.sp(15.5),
                                  fontWeight: FontWeight.w700,
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isWork) ...[
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  'Mon - Fri',
                                  style: TextStyle(
                                    fontSize: context.sp(10.5),
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3.0),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: context.sp(13.0),
                            fontWeight: FontWeight.w500,
                            fontFamily: AppTextStyles.fontFamily,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Trailing (Inline Edit/Delete for default, Radio for unselected)
                  if (isDefault) ...[
                    _buildInlineEditDelete(context, isDark, addressId, title),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.radio_button_unchecked,
                        size: 22.0,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12.0),

              // Address Body
              Text(
                fullDisplayAddress,
                style: TextStyle(
                  fontSize: context.sp(13.0),
                  height: 1.4,
                  fontFamily: AppTextStyles.fontFamily,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 14.0,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6.0),
                  Flexible(
                    child: Text(
                      phone,
                      style: TextStyle(
                        fontSize: context.sp(12.5),
                        fontWeight: FontWeight.w500,
                        fontFamily: AppTextStyles.fontFamily,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Bottom Actions Row for non-default cards
              if (!isDefault) ...[
                const SizedBox(height: 10.0),
                const Divider(height: 16.0, thickness: 0.8),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _handleEditAddress(addressId),
                        borderRadius: BorderRadius.circular(6.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 14.0,
                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: context.sp(12.5),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 18.0),
                      InkWell(
                        onTap: () => _confirmDeleteAddress(addressId, title),
                        borderRadius: BorderRadius.circular(6.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 16.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineEditDelete(
    BuildContext context,
    bool isDark,
    String addressId,
    String title,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _handleEditAddress(addressId),
          borderRadius: BorderRadius.circular(6.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 14.0,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
                const SizedBox(width: 3.0),
                Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: context.sp(12.5),
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTextStyles.fontFamily,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10.0),
        InkWell(
          onTap: () => _confirmDeleteAddress(addressId, title),
          borderRadius: BorderRadius.circular(6.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 16.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }
}
