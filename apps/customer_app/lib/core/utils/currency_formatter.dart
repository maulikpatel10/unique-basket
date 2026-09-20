import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Global centralized Currency Formatter for UNIQUE BASKET.
///
/// Standard configuration:
/// - Currency Code: INR
/// - Currency Symbol: ₹ (positioned before amount)
/// - Locale: en_IN
/// - Formatting: Always rounded without decimals (Indian numbering grouping: e.g. ₹1,25,000)
class CurrencyFormatter {
  CurrencyFormatter._();

  static const String currencySymbol = AppConstants.currencySymbol;
  static const String currencyCode = AppConstants.currencyCode;
  static const String currencyLocale = AppConstants.currencyLocale;

  /// Formatter using Indian numbering system with zero decimal places.
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: currencyLocale,
    symbol: currencySymbol,
    decimalDigits: 0,
    customPattern: '\u00A4#,##,##0',
  );

  /// Formatter without symbol using Indian numbering system with zero decimal places.
  static final NumberFormat _amountOnlyFormatter = NumberFormat.currency(
    locale: currencyLocale,
    symbol: '',
    decimalDigits: 0,
    customPattern: '#,##,##0',
  );

  /// Formats [amount] as currency with symbol and Indian grouping, rounded to whole number.
  /// Example:
  /// - `120` -> `₹120`
  /// - `120.50` -> `₹121`
  /// - `125000` -> `₹1,25,000`
  /// - `0` or `null` -> `₹0`
  static String format(num? amount) {
    if (amount == null) return '${currencySymbol}0';
    final rounded = amount.round();
    return _inrFormatter.format(rounded);
  }

  /// Formats [amount] without currency symbol using Indian grouping, rounded to whole number.
  /// Example:
  /// - `120` -> `120`
  /// - `125000` -> `1,25,000`
  /// - `null` -> `0`
  static String formatAmountOnly(num? amount) {
    if (amount == null) return '0';
    final rounded = amount.round();
    return _amountOnlyFormatter.format(rounded);
  }

  /// Formats [amount] without grouping or symbol as a rounded integer string.
  /// Example:
  /// - `120.45` -> `120`
  /// - `null` -> `0`
  static String formatPlain(num? amount) {
    if (amount == null) return '0';
    return amount.round().toString();
  }
}
