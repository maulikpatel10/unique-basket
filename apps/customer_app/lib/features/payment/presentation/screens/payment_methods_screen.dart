import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_responsive.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../data/models/saved_payment_method_model.dart';
import '../providers/payment_methods_provider.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  void _showDeleteConfirmation(BuildContext context, SavedPaymentMethod method) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Remove Payment Method?',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'Are you sure you want to remove ${method.title}?',
            style: TextStyle(
              fontSize: 14.0,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(dialogCtx).pop();
                await ref
                    .read(paymentMethodsProvider.notifier)
                    .removePaymentMethod(method.id);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${method.title} removed'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF014D40),
                  ),
                );
              },
              child: const Text(
                'Remove',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddPaymentMethodSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetCtx) {
        return _AddPaymentMethodModal(
          onAdd: (method) async {
            final success = await ref
                .read(paymentMethodsProvider.notifier)
                .addPaymentMethod(method);
            if (success) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${method.title} added successfully'),
                  backgroundColor: const Color(0xFF014D40),
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Payment method already exists'),
                  backgroundColor: Color(0xFFDC2626),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7FAFA),
      appBar: AppHeader(
        title: 'Payment Methods',
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
      body: paymentMethodsAsync.when(
        loading: () => const AppLoading(message: 'Loading payment methods...'),
        error: (err, stack) => AppErrorState(
          title: 'Unable to Load Payment Methods',
          message: 'Please try again later.',
          onRetry: () => ref.read(paymentMethodsProvider.notifier).loadPaymentMethods(),
        ),
        data: (methods) {
          if (methods.isEmpty) {
            return _buildEmptyState(context, isDark);
          }
          return _buildMethodList(context, methods, isDark);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_card_off_rounded,
                size: 40,
                color: Color(0xFF014D40),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Saved Payment Methods',
              style: TextStyle(
                fontSize: context.sp(18.0),
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your preferred UPI or Card details for faster checkout.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.sp(14.0),
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 220,
              child: AppButton(
                text: 'Add Payment Method',
                icon: Icons.add_rounded,
                onPressed: () => _showAddPaymentMethodSheet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodList(
    BuildContext context,
    List<SavedPaymentMethod> methods,
    bool isDark,
  ) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await ref.read(paymentMethodsProvider.notifier).loadPaymentMethods();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: context.h(AppSpacing.md),
        ),
        children: [
          // Section header row
          _buildSectionHeader(context, methods.length, isDark),
          const SizedBox(height: AppSpacing.md),

          // Cards
          for (final method in methods) ...[
            _buildPaymentMethodCard(context, method, isDark),
            const SizedBox(height: AppSpacing.md),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Bottom CTA button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: AppButton(
              text: 'Add Payment Method',
              icon: Icons.add_rounded,
              onPressed: () => _showAddPaymentMethodSheet(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, int count, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAVED PAYMENT METHODS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.sp(12.0),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                '$count ${count == 1 ? 'method' : 'methods'} saved for quick checkout',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.sp(12.0),
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: () => _showAddPaymentMethodSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F3A30) : const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: context.sp(14.0),
                  color: const Color(0xFF014D40),
                ),
                const SizedBox(width: 4.0),
                Text(
                  'Add New',
                  style: TextStyle(
                    fontSize: context.sp(12.0),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF014D40),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context,
    SavedPaymentMethod method,
    bool isDark,
  ) {
    final isUPI = method.type == PaymentMethodType.upi;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Icon, Title, Subtitle, Badge
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading Type Icon
                _buildTypeIcon(method.type, isDark),
                const SizedBox(width: 12.0),

                // Name and identifier
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.title,
                        style: TextStyle(
                          fontSize: context.sp(15.0),
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        method.subtitle,
                        style: TextStyle(
                          fontSize: context.sp(12.0),
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8.0),

                // Badge (DEFAULT or Credit / Debit)
                if (method.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF014D40),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: context.sp(10.0),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      method.type.displayBadgeText,
                      style: TextStyle(
                        fontSize: context.sp(11.0),
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Middle row: Masked Card Number if card
          if (!isUPI && method.maskedIdentifier != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md + 40.0 + 12.0,
                right: AppSpacing.md,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                method.maskedIdentifier!,
                style: TextStyle(
                  fontSize: context.sp(14.0),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                ),
              ),
            ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppColors.dividerDark : const Color(0xFFF1F5F9),
          ),

          // Bottom Action Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                // Left: Set as Default OR Fastest checkout info
                if (method.isDefault)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16.0,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            'Fastest checkout option',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.sp(12.0),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4.0),
                      onTap: () => ref
                          .read(paymentMethodsProvider.notifier)
                          .setDefaultPaymentMethod(method.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.radio_button_off_rounded,
                              size: 16.0,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6.0),
                            Flexible(
                              child: Text(
                                'Set as Default',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.sp(12.0),
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Right: Remove Button
                InkWell(
                  borderRadius: BorderRadius.circular(4.0),
                  onTap: () => _showDeleteConfirmation(context, method),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 16.0,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: context.sp(12.0),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(PaymentMethodType type, bool isDark) {
    Color bg;
    IconData icon;
    Color iconColor;

    switch (type) {
      case PaymentMethodType.upi:
        bg = const Color(0xFFE6F4EA);
        icon = Icons.account_balance_wallet_rounded;
        iconColor = const Color(0xFF014D40);
        break;
      case PaymentMethodType.creditCard:
        bg = const Color(0xFFEFF6FF);
        icon = Icons.credit_card_rounded;
        iconColor = const Color(0xFF2563EB);
        break;
      case PaymentMethodType.debitCard:
        bg = const Color(0xFFFFF7ED);
        icon = Icons.credit_score_rounded;
        iconColor = const Color(0xFFEA580C);
        break;
    }

    return Container(
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : bg,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Icon(
        icon,
        size: 22.0,
        color: iconColor,
      ),
    );
  }
}

/// Modal bottom sheet for adding a new local payment method safely.
class _AddPaymentMethodModal extends StatefulWidget {
  final Future<void> Function(SavedPaymentMethod method) onAdd;

  const _AddPaymentMethodModal({required this.onAdd});

  @override
  State<_AddPaymentMethodModal> createState() => _AddPaymentMethodModalState();
}

class _AddPaymentMethodModalState extends State<_AddPaymentMethodModal> {
  PaymentMethodType _selectedType = PaymentMethodType.upi;

  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _cardLast4Controller = TextEditingController();
  final _expiryController = TextEditingController();
  final _cardholderController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _updateDefaultFields();
  }

  void _updateDefaultFields() {
    if (_selectedType == PaymentMethodType.upi) {
      _titleController.text = 'Google Pay / UPI';
      _subtitleController.text = '';
    } else if (_selectedType == PaymentMethodType.creditCard) {
      _titleController.text = 'Visa Credit Card';
      _cardholderController.text = 'Customer';
      _expiryController.text = '12/28';
    } else {
      _titleController.text = 'Debit Card';
      _cardholderController.text = 'Customer';
      _expiryController.text = '12/28';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _cardLast4Controller.dispose();
    _expiryController.dispose();
    _cardholderController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final id = 'pm-${DateTime.now().millisecondsSinceEpoch}';
    final title = _titleController.text.trim();

    SavedPaymentMethod method;

    if (_selectedType == PaymentMethodType.upi) {
      final upiId = _subtitleController.text.trim();
      method = SavedPaymentMethod(
        id: id,
        type: PaymentMethodType.upi,
        title: title,
        subtitle: upiId,
      );
    } else {
      final last4 = _cardLast4Controller.text.trim();
      final expiry = _expiryController.text.trim();
      final holder = _cardholderController.text.trim();
      final masked = '••••  ••••  ••••  $last4';
      final subtitle = 'Expires: $expiry  ·  $holder';

      method = SavedPaymentMethod(
        id: id,
        type: _selectedType,
        title: title,
        subtitle: subtitle,
        maskedIdentifier: masked,
      );
    }

    Navigator.of(context).pop();
    widget.onAdd(method);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: bottomInset + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Payment Method',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              // Safe Notice Banner
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F2D25) : const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 18.0,
                      color: Color(0xFF014D40),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Preferences are saved locally for quick selection. CVV or card passwords are never requested.',
                        style: TextStyle(
                          fontSize: 11.0,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF014D40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Type Selector Chips
              Text(
                'Payment Method Type',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  _buildTypeChip(PaymentMethodType.upi, 'UPI', isDark),
                  _buildTypeChip(PaymentMethodType.creditCard, 'Credit Card', isDark),
                  _buildTypeChip(PaymentMethodType.debitCard, 'Debit Card', isDark),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Title input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _selectedType == PaymentMethodType.upi
                      ? 'Display Title (e.g. Google Pay / UPI)'
                      : 'Card Name (e.g. HDFC Bank Visa Card)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 12.0),

              // Conditional Fields
              if (_selectedType == PaymentMethodType.upi) ...[
                TextFormField(
                  controller: _subtitleController,
                  decoration: InputDecoration(
                    labelText: 'UPI ID (e.g. user@okhdfcbank)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty || !val.contains('@'))
                          ? 'Please enter a valid UPI ID (e.g. user@bank)'
                          : null,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cardLast4Controller,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Last 4 Digits',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length != 4) {
                            return 'Enter 4 digits';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _expiryController,
                        decoration: InputDecoration(
                          labelText: 'Expiry (MM/YY)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: _cardholderController,
                  decoration: InputDecoration(
                    labelText: 'Cardholder Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Required' : null,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // Submit Button
              AppButton(
                text: 'Save Payment Method',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(PaymentMethodType type, String label, bool isDark) {
    final isSelected = _selectedType == type;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF014D40),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? AppColors.textPrimaryDark : const Color(0xFF334155)),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
            _updateDefaultFields();
          });
        }
      },
    );
  }
}
