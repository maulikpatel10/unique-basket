import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../data/models/saved_payment_method_model.dart';

final paymentMethodsProvider =
    StateNotifierProvider<PaymentMethodsNotifier, AsyncValue<List<SavedPaymentMethod>>>(
  (ref) {
    final localStorage = ref.watch(localStorageProvider);
    return PaymentMethodsNotifier(localStorage);
  },
);

class PaymentMethodsNotifier extends StateNotifier<AsyncValue<List<SavedPaymentMethod>>> {
  final LocalStorageService _storage;

  PaymentMethodsNotifier(this._storage) : super(const AsyncValue.loading()) {
    loadPaymentMethods();
  }

  /// Canonical initial seed data matching the reference design.
  static final List<SavedPaymentMethod> defaultSeedMethods = [
    const SavedPaymentMethod(
      id: 'pm-1',
      type: PaymentMethodType.upi,
      title: 'Google Pay / UPI',
      subtitle: 'maulik@okhdfcbank',
      maskedIdentifier: null,
      isDefault: true,
    ),
    const SavedPaymentMethod(
      id: 'pm-2',
      type: PaymentMethodType.creditCard,
      title: 'HDFC Bank Visa Card',
      subtitle: 'Expires: 08/28  ·  Maulik Patel',
      maskedIdentifier: '••••  ••••  ••••  4242',
      isDefault: false,
    ),
    const SavedPaymentMethod(
      id: 'pm-3',
      type: PaymentMethodType.debitCard,
      title: 'ICICI Bank Debit Card',
      subtitle: 'Expires: 11/27  ·  Maulik Patel',
      maskedIdentifier: '••••  ••••  ••••  8891',
      isDefault: false,
    ),
  ];

  /// Loads saved payment methods from local storage.
  Future<void> loadPaymentMethods() async {
    state = const AsyncValue.loading();
    try {
      final raw = _storage.getString(AppConstants.keySavedPaymentMethods);
      if (raw == null) {
        // Initial first-time load: seed with default reference methods
        final seed = defaultSeedMethods;
        await _saveToStorage(seed);
        if (!mounted) return;
        state = AsyncValue.data(seed);
        return;
      }

      final decoded = jsonDecode(raw);
      if (!mounted) return;
      if (decoded is List) {
        final methods = decoded
            .map((e) => SavedPaymentMethod.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        state = AsyncValue.data(methods);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  /// Sets the specified payment method as default and all others as non-default.
  Future<void> setDefaultPaymentMethod(String id) async {
    final current = state.valueOrNull ?? [];
    final updated = current.map((item) {
      return item.copyWith(isDefault: item.id == id);
    }).toList();

    if (!mounted) return;
    state = AsyncValue.data(updated);
    await _saveToStorage(updated);
  }

  /// Removes a payment method by ID.
  /// If the removed method was default and other methods remain, the first remaining method becomes default.
  Future<void> removePaymentMethod(String id) async {
    final current = state.valueOrNull ?? [];
    final targetIndex = current.indexWhere((m) => m.id == id);
    if (targetIndex == -1) return;

    final wasDefault = current[targetIndex].isDefault;
    final remaining = current.where((m) => m.id != id).toList();

    if (wasDefault && remaining.isNotEmpty) {
      // Reassign default to the first remaining payment method
      final updated = <SavedPaymentMethod>[];
      for (var i = 0; i < remaining.length; i++) {
        updated.add(remaining[i].copyWith(isDefault: i == 0));
      }
      if (!mounted) return;
      state = AsyncValue.data(updated);
      await _saveToStorage(updated);
    } else {
      if (!mounted) return;
      state = AsyncValue.data(remaining);
      await _saveToStorage(remaining);
    }
  }

  /// Adds a new safe display payment method.
  /// Returns false if duplicate detected, true if added successfully.
  Future<bool> addPaymentMethod(SavedPaymentMethod newMethod) async {
    final current = state.valueOrNull ?? [];

    // Duplicate detection: check if identifier or subtitle matches
    final isDuplicate = current.any((m) {
      if (newMethod.type == PaymentMethodType.upi) {
        return m.type == PaymentMethodType.upi &&
            m.subtitle.trim().toLowerCase() == newMethod.subtitle.trim().toLowerCase();
      } else {
        return m.maskedIdentifier != null &&
            newMethod.maskedIdentifier != null &&
            m.maskedIdentifier!.replaceAll(' ', '') ==
                newMethod.maskedIdentifier!.replaceAll(' ', '');
      }
    });

    if (isDuplicate) {
      return false;
    }

    final makeDefault = current.isEmpty || newMethod.isDefault;
    final updatedList = <SavedPaymentMethod>[];

    for (final item in current) {
      updatedList.add(makeDefault ? item.copyWith(isDefault: false) : item);
    }

    updatedList.add(newMethod.copyWith(isDefault: makeDefault));
    if (!mounted) return false;
    state = AsyncValue.data(updatedList);
    await _saveToStorage(updatedList);
    return true;
  }

  Future<void> _saveToStorage(List<SavedPaymentMethod> methods) async {
    final jsonString = jsonEncode(methods.map((m) => m.toJson()).toList());
    await _storage.setString(AppConstants.keySavedPaymentMethods, jsonString);
  }
}
