import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../address/presentation/providers/customer_address_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../checkout/presentation/providers/order_provider.dart';
import '../../../profile_setup/presentation/providers/customer_profile_provider.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_menu_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _handleNavigation(BuildContext context, String destination) {
    try {
      if (destination == RouteNames.notifications) {
        GoRouter.of(context).push(RouteNames.notifications);
      } else if (destination == RouteNames.favorites) {
        GoRouter.of(context).push(RouteNames.favorites);
      } else if (destination == RouteNames.editProfile || destination == 'Edit Profile') {
        GoRouter.of(context).push(RouteNames.editProfile);
      } else if (destination == RouteNames.myOrders || destination == 'My Orders') {
        GoRouter.of(context).push(RouteNames.myOrders);
      } else if (destination == RouteNames.myAddresses || destination == 'My Addresses') {
        GoRouter.of(context).push(RouteNames.myAddresses);
      } else if (destination == RouteNames.paymentMethods || destination == 'Payment Methods') {
        GoRouter.of(context).push(RouteNames.paymentMethods);
      } else if (destination == RouteNames.helpSupport || destination == 'Help & Support') {
        GoRouter.of(context).push(RouteNames.helpSupport);
      } else {
        // Safe placeholder for pending profile sub-screens (Screens 27–34)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$destination coming soon'),
            duration: const Duration(milliseconds: 800),
            backgroundColor: const Color(0xFF014D40),
          ),
        );
      }
    } catch (_) {
      // Safe fallback for widget tests without GoRouter
    }
  }

  void _showLogoutConfirmationSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.0)),
      ),
      constraints: BoxConstraints(
        maxWidth: context.isTabletOrLarger ? AppBreakpoints.maxFormWidth : double.infinity,
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.sm,
              bottom: sheetCtx.h(AppSpacing.lg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40.0,
                    height: 4.0,
                    margin: const EdgeInsets.only(top: 4.0, bottom: 20.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),

                // Soft-red circular logout icon badge
                Container(
                  width: 58.0,
                  height: 58.0,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A1215) : const Color(0xFFFFF1F2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.logout_rounded,
                      size: sheetCtx.sp(26.0),
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
                SizedBox(height: sheetCtx.h(18.0)),

                // Centered title
                Text(
                  'Logout from UNIQUE BASKET?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: sheetCtx.sp(18.0),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: sheetCtx.h(10.0)),

                // Centered description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Are you sure you want to log out of your account? You can sign in again anytime using your mobile number.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: sheetCtx.sp(13.5),
                      height: 1.45,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(height: sheetCtx.h(24.0)),

                // Primary full-width pill button: "Log Out" (using reusable AppButton)
                AppButton(
                  text: 'Log Out',
                  variant: ButtonVariant.danger,
                  borderRadius: BorderRadius.circular(999.0),
                  onPressed: () async {
                    Navigator.of(sheetCtx).pop();
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      try {
                        GoRouter.of(context).go(RouteNames.mobileNumber);
                      } catch (_) {}
                    }
                  },
                ),
                SizedBox(height: sheetCtx.h(12.0)),

                // Secondary full-width pill button: "Cancel"
                SizedBox(
                  width: double.infinity,
                  height: context.r(52.0).clamp(48.0, 56.0),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      foregroundColor: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: sheetCtx.sp(15.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionFooter(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        top: context.h(8.0),
        bottom: context.h(24.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_rounded,
            size: context.sp(14.0),
            color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6.0),
          Text(
            '•  v2.4.1',
            style: TextStyle(
              fontSize: context.sp(12.0),
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Local photo path fallback
    final localStorage = ref.watch(localStorageProvider);
    final localUserData = localStorage.getJson(AppConstants.keyUserData);
    final localPhotoPath = localUserData?['photoPath'] as String?;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Profile',
        showBackButton: false,
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
        foregroundColor: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22.0),
          bottomRight: Radius.circular(22.0),
        ),
      ),
      body: profileAsync.when(
        loading: () => const AppLoading(message: 'Loading profile...'),
        error: (err, stack) {
          if (localUserData != null) {
            return _buildContent(
              context,
              ref,
              localUserData,
              localPhotoPath,
              isDark,
            );
          }
          return AppErrorState(
            title: 'Unable to Load Profile',
            message: 'Please check your connection and try again.',
            onRetry: () => ref.refresh(customerProfileProvider),
          );
        },
        data: (profileData) {
          final effectiveData = profileData ?? localUserData ?? {};
          return _buildContent(
            context,
            ref,
            effectiveData,
            localPhotoPath,
            isDark,
          );
        },
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: 4,
        onTabSelected: (index) {
          if (index == 0) {
            GoRouter.of(context).go(RouteNames.home);
          } else if (index == 1) {
            GoRouter.of(context).go(RouteNames.explore);
          } else if (index == 2) {
            try {
              GoRouter.of(context).push(RouteNames.cart);
            } catch (_) {}
          } else if (index == 3) {
            try {
              GoRouter.of(context).push(RouteNames.favorites);
            } catch (_) {}
          }
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
    String? localPhotoPath,
    bool isDark,
  ) {
    final name = data['name'] as String?;
    final phone = data['phone'] as String?;
    final photoPath = data['photoPath'] as String? ?? localPhotoPath;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(customerProfileProvider);
        ref.invalidate(customerOrdersProvider);
        ref.invalidate(customerAddressesProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          top: AppSpacing.xs,
          bottom: context.h(AppSpacing.lg),
        ),
        children: [
          // 1. Open Profile Header (Avatar, Name, Phone, Verified, Edit Action)
          ProfileHeaderCard(
            name: name,
            phone: phone,
            photoPath: photoPath,
            onEditTap: () => _handleNavigation(context, 'Edit Profile'),
          ),

          // Subtle Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Divider(
              height: 1,
              thickness: 0.8,
              color: isDark ? AppColors.dividerDark : const Color(0xFFF1F5F9),
            ),
          ),
          SizedBox(height: context.h(AppSpacing.xs)),

          // 2. MY ACCOUNT Section (Open List)
          ProfileMenuSection(
            sectionTitle: 'MY ACCOUNT',
            items: [
              ProfileMenuRowItem(
                title: 'My Orders',
                subtitle: 'View your recent orders',
                icon: Icons.inventory_2_outlined,
                iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF014D40),
                iconBgColor: isDark ? const Color(0xFF00382E) : const Color(0xFFE6F4EA),
                onTap: () => _handleNavigation(context, 'My Orders'),
              ),
              ProfileMenuRowItem(
                title: 'My Addresses',
                subtitle: 'Manage delivery addresses',
                icon: Icons.location_on_outlined,
                iconColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                iconBgColor: isDark ? const Color(0xFF042F2E) : const Color(0xFFCCFBF1),
                onTap: () => _handleNavigation(context, 'My Addresses'),
              ),
              ProfileMenuRowItem(
                title: 'Payment Methods',
                subtitle: 'Manage saved payment options',
                icon: Icons.credit_card_outlined,
                iconColor: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                iconBgColor: isDark ? const Color(0xFF2E1065) : const Color(0xFFEDE9FE),
                onTap: () => _handleNavigation(context, 'Payment Methods'),
              ),
            ],
          ),

          // Subtle Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Divider(
              height: 1,
              thickness: 0.8,
              color: isDark ? AppColors.dividerDark : const Color(0xFFF1F5F9),
            ),
          ),
          SizedBox(height: context.h(AppSpacing.xs)),

          // 3. PREFERENCES Section (Open List)
          ProfileMenuSection(
            sectionTitle: 'PREFERENCES',
            items: [
              ProfileMenuRowItem(
                title: 'Notifications',
                subtitle: 'Order updates and offers',
                icon: Icons.notifications_none_rounded,
                iconColor: isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
                iconBgColor: isDark ? const Color(0xFF431407) : const Color(0xFFFFEDD5),
                onTap: () => _handleNavigation(context, RouteNames.notifications),
              ),
            ],
          ),

          // Subtle Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Divider(
              height: 1,
              thickness: 0.8,
              color: isDark ? AppColors.dividerDark : const Color(0xFFF1F5F9),
            ),
          ),
          SizedBox(height: context.h(AppSpacing.xs)),

          // 4. SUPPORT Section (Open List including Log Out)
          ProfileMenuSection(
            sectionTitle: 'SUPPORT',
            items: [
              ProfileMenuRowItem(
                title: 'Help & Support',
                subtitle: 'Get help with your order',
                icon: Icons.help_outline_rounded,
                iconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                iconBgColor: isDark ? const Color(0xFF082F49) : const Color(0xFFE0F2FE),
                onTap: () => _handleNavigation(context, 'Help & Support'),
              ),
              ProfileMenuRowItem(
                title: 'Log Out',
                subtitle: 'Sign out from your account',
                icon: Icons.logout_rounded,
                iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                iconBgColor: isDark ? const Color(0xFF2A1215) : const Color(0xFFFFF1F2),
                titleColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                onTap: () => _showLogoutConfirmationSheet(context, ref),
              ),
            ],
          ),

          SizedBox(height: context.h(AppSpacing.sm)),

          // 5. Version Footer
          _buildVersionFooter(context, isDark),
        ],
      ),
    );
  }
}
