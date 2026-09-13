import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  static final NumberFormat _inrNoDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  static String format(num? amount) {
    if (amount == null) return '${AppConstants.currencySymbol}0';
    if (amount % 1 == 0) {
      return _inrNoDecimals.format(amount);
    }
    return _inrFormatter.format(amount);
  }

  static String formatPlain(num? amount) {
    if (amount == null) return '0.00';
    return amount.toStringAsFixed(2);
  }
}
