import 'package:flutter/foundation.dart';

/// Supported types of locally saved payment method preferences.
enum PaymentMethodType {
  upi,
  creditCard,
  debitCard;

  static PaymentMethodType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'upi':
        return PaymentMethodType.upi;
      case 'credit_card':
      case 'creditcard':
      case 'credit':
        return PaymentMethodType.creditCard;
      case 'debit_card':
      case 'debitcard':
      case 'debit':
        return PaymentMethodType.debitCard;
      default:
        return PaymentMethodType.upi;
    }
  }

  String toDbString() {
    switch (this) {
      case PaymentMethodType.upi:
        return 'upi';
      case PaymentMethodType.creditCard:
        return 'credit_card';
      case PaymentMethodType.debitCard:
        return 'debit_card';
    }
  }

  String get displayBadgeText {
    switch (this) {
      case PaymentMethodType.upi:
        return 'UPI';
      case PaymentMethodType.creditCard:
        return 'Credit';
      case PaymentMethodType.debitCard:
        return 'Debit';
    }
  }
}

/// Client-managed display model for saved payment methods.
///
/// NOTE: This model stores ONLY display metadata and local default preference.
/// Sensitive payment data (CVV, full card numbers, PINs, passwords) are NEVER stored.
@immutable
class SavedPaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String title;
  final String subtitle;
  final String? maskedIdentifier;
  final bool isDefault;

  const SavedPaymentMethod({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.maskedIdentifier,
    this.isDefault = false,
  });

  SavedPaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? title,
    String? subtitle,
    String? maskedIdentifier,
    bool? isDefault,
  }) {
    return SavedPaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      maskedIdentifier: maskedIdentifier ?? this.maskedIdentifier,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toDbString(),
      'title': title,
      'subtitle': subtitle,
      'maskedIdentifier': maskedIdentifier,
      'isDefault': isDefault,
    };
  }

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id']?.toString() ?? '',
      type: PaymentMethodType.fromString(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      maskedIdentifier: json['maskedIdentifier']?.toString(),
      isDefault: json['isDefault'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedPaymentMethod &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          title == other.title &&
          subtitle == other.subtitle &&
          maskedIdentifier == other.maskedIdentifier &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      title.hashCode ^
      subtitle.hashCode ^
      maskedIdentifier.hashCode ^
      isDefault.hashCode;
}
