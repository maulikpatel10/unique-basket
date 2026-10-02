import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../checkout/presentation/providers/order_provider.dart';
import '../../../orders/presentation/screens/order_details_screen.dart';
import '../../../orders/presentation/screens/order_tracking_screen.dart';

/// Screen 33 — Help & Support Screen matching 33_Help_Support.png.
class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  static const String supportPhone = '+91 98765 43210';
  static const String supportEmail = 'support@uniquebasket.com';

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    HapticFeedback.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        GoRouter.of(context).go(RouteNames.profile);
      } catch (_) {}
    }
  }

  void _showOrdersDeliveryHelp(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: Color(0xFF014D40),
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Text(
                        'Orders & Delivery Help',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildHelpFaqItem(
                context,
                title: 'How do I track my active order?',
                body: 'Go to My Orders and tap on the active order card to view live status updates from packing to doorstep delivery.',
                isDark: isDark,
              ),
              const SizedBox(height: 12.0),
              _buildHelpFaqItem(
                context,
                title: 'What are the delivery hours in Rajkot?',
                body: 'We deliver fresh produce between 7:00 AM and 9:00 PM daily across all serviceable pincodes in Rajkot.',
                isDark: isDark,
              ),
              const SizedBox(height: 12.0),
              _buildHelpFaqItem(
                context,
                title: 'What if an item is damaged or missing?',
                body: 'Please contact our customer champions via Call or Chat within 24 hours of delivery for immediate refund or replacement assistance.',
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'View My Orders',
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  try {
                    context.push(RouteNames.myOrders);
                  } catch (_) {}
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentsRefundsHelp(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFF014D40),
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Text(
                        'Payments & Refunds Help',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildHelpFaqItem(
                context,
                title: 'What payment methods are supported?',
                body: 'We support UPI (Google Pay, PhonePe, Paytm, BHIM) and Pay On Delivery / Cash on Delivery (COD).',
                isDark: isDark,
              ),
              const SizedBox(height: 12.0),
              _buildHelpFaqItem(
                context,
                title: 'How long does a refund take?',
                body: 'UPI refunds are typically credited back to the source bank account within 3 to 5 business days after approval.',
                isDark: isDark,
              ),
              const SizedBox(height: 12.0),
              _buildHelpFaqItem(
                context,
                title: 'Can I manage my saved payment methods?',
                body: 'Yes! Navigate to Profile > Payment Methods to add, remove, or set your default payment preference.',
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'Manage Payment Methods',
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  try {
                    context.push(RouteNames.paymentMethods);
                  } catch (_) {}
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOrderHelpActionDialog(BuildContext context, Map<String, dynamic> order) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final orderId = (order['id'] as String? ?? '').trim();
    final rawNumber = (order['orderNumber'] as String? ?? '').trim();
    final orderNumber = rawNumber.isNotEmpty
        ? (rawNumber.startsWith('#') ? rawNumber : '#$rawNumber')
        : '#UB-20260908-015';

    final extraData = {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'order': order,
      if (order['items'] != null) 'items': order['items'],
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help with $orderNumber',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Choose an option below to get immediate assistance with this active order.',
                style: TextStyle(
                  fontSize: 13.0,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(Icons.navigation_outlined, color: Color(0xFF014D40)),
                ),
                title: const Text('Track Live Delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Check current preparation and dispatch status'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(ctx).pop();
                  try {
                    context.push(RouteNames.orderTracking, extra: extraData);
                  } catch (_) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(
                          orderId: orderId,
                          orderNumber: orderNumber,
                          initialOrderData: extraData,
                        ),
                      ),
                    );
                  }
                },
              ),
              Divider(color: isDark ? AppColors.dividerDark : const Color(0xFFF1F5F9)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF2563EB)),
                ),
                title: const Text('View Full Order Details', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Review ordered items, delivery address & bill summary'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(ctx).pop();
                  try {
                    context.push(RouteNames.orderDetails, extra: extraData);
                  } catch (_) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsScreen(
                          orderId: orderId,
                          orderNumber: orderNumber,
                          initialOrderData: extraData,
                        ),
                      ),
                    );
                  }
                },
              ),
              Divider(color: isDark ? AppColors.dividerDark : const Color(0xFFF1F5F9)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(Icons.headset_mic_outlined, color: Color(0xFFEA580C)),
                ),
                title: const Text('Contact Customer Support', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Call our support champion for urgent queries'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleCallSupport(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleChatWithUs(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF014D40),
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 10.0),
              Text(
                'Customer Support Chat',
                style: TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Our customer care champions are available to assist you via WhatsApp and Email.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F2D25) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E5244) : const Color(0xFFBBF7D0),
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 16.0, color: Color(0xFF014D40)),
                        SizedBox(width: 8.0),
                        Text(
                          HelpSupportScreen.supportPhone,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF014D40),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 16.0, color: Color(0xFF014D40)),
                        const SizedBox(width: 8.0),
                        Text(
                          HelpSupportScreen.supportEmail,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: HelpSupportScreen.supportPhone));
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support contact copied to clipboard (+91 98765 43210)'),
                    backgroundColor: Color(0xFF014D40),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF014D40),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Copy Contact'),
            ),
          ],
        );
      },
    );
  }

  void _handleCallSupport(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFF014D40),
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 10.0),
              Text(
                'Call Support',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Speak directly with a UNIQUE BASKET customer care champion.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F2D25) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E5244) : const Color(0xFFBBF7D0),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call_rounded, size: 20.0, color: Color(0xFF014D40)),
                    SizedBox(width: 8.0),
                    Text(
                      HelpSupportScreen.supportPhone,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF014D40),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: HelpSupportScreen.supportPhone));
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support phone number copied: +91 98765 43210'),
                    backgroundColor: Color(0xFF014D40),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF014D40),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Call / Copy'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpFaqItem(
    BuildContext context, {
    required String title,
    required String body,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            body,
            style: TextStyle(
              fontSize: 12.0,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ordersAsync = ref.watch(customerOrdersProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
      appBar: AppHeader(
        title: 'Help & Support',
        showBackButton: true,
        onBackTap: () => _handleBack(context),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFF014D40),
        foregroundColor: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22.0),
          bottomRight: Radius.circular(22.0),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: context.h(AppSpacing.md),
          ),
          children: [
            // 1. Search Bar
            _buildSearchBar(context, isDark),
            const SizedBox(height: AppSpacing.lg),

            // When searching, show filtered content or empty state
            if (_searchQuery.isNotEmpty)
              ..._buildFilteredSearchResults(context, isDark, ordersAsync)
            else ...[
              // 2. QUICK HELP Section
              _buildQuickHelpSection(context, isDark),
              const SizedBox(height: AppSpacing.lg),

              // 3. NEED HELP WITH AN ORDER? Section
              _buildOrderHelpSection(context, isDark, ordersAsync),
              const SizedBox(height: AppSpacing.lg),

              // 4. Still Need Help? Contact Card
              _buildStillNeedHelpCard(context, isDark),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: context.sp(14.0),
          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Search orders, payments, delivery...',
          hintStyle: TextStyle(
            fontSize: context.sp(13.5),
            color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF014D40),
            size: 22.0,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18.0),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
      ),
    );
  }

  Widget _buildQuickHelpSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK HELP',
          style: TextStyle(
            fontSize: context.sp(12.0),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            // Card 1: Orders & Delivery
            Expanded(
              child: _buildQuickHelpCard(
                context,
                title: 'Orders & Delivery',
                subtitle: 'Track, modify, or get order assistance',
                icon: Icons.shopping_bag_outlined,
                onTap: () => _showOrdersDeliveryHelp(context),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Card 2: Payments & Refunds
            Expanded(
              child: _buildQuickHelpCard(
                context,
                title: 'Payments & Refunds',
                subtitle: 'UPI, wallet, cashback & refund status',
                icon: Icons.credit_card_outlined,
                onTap: () => _showPaymentsRefundsHelp(context),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickHelpCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42.0,
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F3A30) : const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(
                    icon,
                    size: 22.0,
                    color: const Color(0xFF014D40),
                  ),
                ),
                const SizedBox(height: 14.0),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.sp(14.0),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: context.sp(11.5),
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHelpSection(
    BuildContext context,
    bool isDark,
    AsyncValue<List<dynamic>> ordersAsync,
  ) {
    return ordersAsync.when(
      loading: () => Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: const AppLoading(message: 'Checking active orders...'),
      ),
      error: (err, stack) => _buildNoActiveOrderCard(context, isDark),
      data: (ordersRaw) {
        final orders = ordersRaw.whereType<Map<String, dynamic>>().toList();
        final activeOrder = orders.firstWhere(
          (o) {
            final status = (o['orderStatus'] as String? ?? '').toUpperCase();
            return status == 'PLACED' ||
                status == 'CONFIRMED' ||
                status == 'PREPARING' ||
                status == 'READY_FOR_PICKUP' ||
                status == 'PICKED_UP' ||
                status == 'OUT_FOR_DELIVERY';
          },
          orElse: () => <String, dynamic>{},
        );

        if (activeOrder.isEmpty) {
          return _buildNoActiveOrderCard(context, isDark);
        }

        return _buildActiveOrderCard(context, isDark, activeOrder);
      },
    );
  }

  Widget _buildActiveOrderCard(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> order,
  ) {
    final rawNumber = (order['orderNumber'] as String? ?? '').trim();
    final orderNumber = rawNumber.isNotEmpty
        ? (rawNumber.startsWith('#') ? rawNumber : '#$rawNumber')
        : '#UB-20260908-015';

    final status = (order['orderStatus'] as String? ?? 'PREPARING').toUpperCase();
    String statusDesc;
    switch (status) {
      case 'PLACED':
      case 'CONFIRMED':
        statusDesc = 'Order confirmed & assigned to store';
        break;
      case 'PREPARING':
        statusDesc = 'Preparing your fresh groceries';
        break;
      case 'READY_FOR_PICKUP':
      case 'PICKED_UP':
      case 'OUT_FOR_DELIVERY':
        statusDesc = 'Out for delivery to your address';
        break;
      default:
        statusDesc = 'In progress';
    }

    final totalAmount = (order['totalAmount'] as num?)?.toDouble() ?? 500.0;
    final items = order['items'] as List<dynamic>?;
    final itemCount = items?.length ?? (order['itemCount'] as num?)?.toInt() ?? 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NEED HELP WITH AN ORDER?',
              style: TextStyle(
                fontSize: context.sp(12.0),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7.0,
                  height: 7.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5.0),
                Text(
                  'Active Order',
                  style: TextStyle(
                    fontSize: context.sp(12.0),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF014D40),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top info row
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F3A30) : const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 22.0,
                        color: Color(0xFF014D40),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                orderNumber,
                                style: TextStyle(
                                  fontSize: context.sp(15.0),
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 6.0),
                              Container(
                                width: 6.0,
                                height: 6.0,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF059669),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            statusDesc,
                            style: TextStyle(
                              fontSize: context.sp(12.0),
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Row(
                            children: [
                              Text(
                                CurrencyFormatter.format(totalAmount),
                                style: TextStyle(
                                  fontSize: context.sp(13.0),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF014D40),
                                ),
                              ),
                              Text(
                                ' · $itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                style: TextStyle(
                                  fontSize: context.sp(12.0),
                                  fontWeight: FontWeight.w400,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action button row
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F3A30) : const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () => _showOrderHelpActionDialog(context, order),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Help With This Order',
                              style: TextStyle(
                                fontSize: context.sp(13.5),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF014D40),
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16.0,
                              color: Color(0xFF014D40),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveOrderCard(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEED HELP WITH AN ORDER?',
          style: TextStyle(
            fontSize: context.sp(12.0),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF64748B),
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Active Orders',
                          style: TextStyle(
                            fontSize: context.sp(14.0),
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'View your past order history or place a new order for assistance.',
                          style: TextStyle(
                            fontSize: context.sp(12.0),
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: () {
                  try {
                    context.push(RouteNames.myOrders);
                  } catch (_) {}
                },
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Text(
                        'View Order History',
                        style: TextStyle(
                          fontSize: context.sp(13.0),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF014D40),
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14.0,
                        color: Color(0xFF014D40),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStillNeedHelpCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Still need help?',
            style: TextStyle(
              fontSize: context.sp(17.0),
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Our customer care champions are always here for you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.sp(13.0),
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Button 1: Chat With Us (Solid green)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF014D40),
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(30.0),
                onTap: () => _handleChatWithUs(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 18.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Chat With Us',
                        style: TextStyle(
                          fontSize: context.sp(14.0),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12.0),

          // Button 2: Call Support (Soft mint)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F3A30) : const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(30.0),
                onTap: () => _handleCallSupport(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF014D40),
                        size: 18.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Call Support',
                        style: TextStyle(
                          fontSize: context.sp(14.0),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF014D40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredSearchResults(
    BuildContext context,
    bool isDark,
    AsyncValue<List<dynamic>> ordersAsync,
  ) {
    final query = _searchQuery;

    final allTopics = [
      {
        'category': 'Orders & Delivery',
        'title': 'Track Live Delivery',
        'desc': 'Track your active grocery delivery in real-time.',
        'onTap': () => _showOrdersDeliveryHelp(context),
      },
      {
        'category': 'Orders & Delivery',
        'title': 'Order Modifications or Cancellation',
        'desc': 'How to cancel or edit items in your placed order.',
        'onTap': () => _showOrdersDeliveryHelp(context),
      },
      {
        'category': 'Payments & Refunds',
        'title': 'UPI & Online Payment Methods',
        'desc': 'Managing Google Pay, PhonePe, Paytm or Card options.',
        'onTap': () => _showPaymentsRefundsHelp(context),
      },
      {
        'category': 'Payments & Refunds',
        'title': 'Refund Status & Timeline',
        'desc': 'Refund processing timeframes for cancelled items.',
        'onTap': () => _showPaymentsRefundsHelp(context),
      },
    ];

    final matched = allTopics.where((t) {
      final category = (t['category'] as String).toLowerCase();
      final title = (t['title'] as String).toLowerCase();
      final desc = (t['desc'] as String).toLowerCase();
      return category.contains(query) || title.contains(query) || desc.contains(query);
    }).toList();

    if (matched.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48.0,
                  color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'No matching help topics found',
                  style: TextStyle(
                    fontSize: context.sp(15.0),
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Try searching with different keywords like "orders", "refund", or "delivery".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.sp(12.5),
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => _searchController.clear(),
                  child: const Text('Clear Search'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      Text(
        'SEARCH RESULTS (${matched.length})',
        style: TextStyle(
          fontSize: context.sp(12.0),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      for (final topic in matched) ...[
        Container(
          margin: const EdgeInsets.only(bottom: 10.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14.0),
            child: ListTile(
              title: Text(
                topic['title'] as String,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                topic['desc'] as String,
                style: TextStyle(
                  fontSize: 12.0,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14.0),
              onTap: topic['onTap'] as VoidCallback,
            ),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      _buildStillNeedHelpCard(context, isDark),
    ];
  }
}
