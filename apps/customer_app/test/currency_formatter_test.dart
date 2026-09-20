import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/core/utils/currency_formatter.dart';
import 'package:customer_app/core/constants/app_constants.dart';

void main() {
  group('CurrencyFormatter Unit Tests', () {
    test('Constants match app requirements', () {
      expect(CurrencyFormatter.currencySymbol, '₹');
      expect(CurrencyFormatter.currencyCode, 'INR');
      expect(CurrencyFormatter.currencyLocale, 'en_IN');
      expect(AppConstants.currencySymbol, '₹');
      expect(AppConstants.currencyCode, 'INR');
      expect(AppConstants.currencyLocale, 'en_IN');
    });

    test('Formats null or zero values as ₹0', () {
      expect(CurrencyFormatter.format(null), '₹0');
      expect(CurrencyFormatter.format(0), '₹0');
      expect(CurrencyFormatter.format(0.0), '₹0');
    });

    test('Formats standard whole numbers without decimal places', () {
      expect(CurrencyFormatter.format(50), '₹50');
      expect(CurrencyFormatter.format(99), '₹99');
      expect(CurrencyFormatter.format(120), '₹120');
      expect(CurrencyFormatter.format(250), '₹250');
    });

    test('Rounds decimal values off without displaying decimal places', () {
      expect(CurrencyFormatter.format(120.4), '₹120');
      expect(CurrencyFormatter.format(120.5), '₹121');
      expect(CurrencyFormatter.format(149.50), '₹150');
      expect(CurrencyFormatter.format(4.99), '₹5');
      expect(CurrencyFormatter.format(14.97), '₹15');
    });

    test('Formats large numbers using Indian numbering grouping', () {
      expect(CurrencyFormatter.format(1000), '₹1,000');
      expect(CurrencyFormatter.format(1250), '₹1,250');
      expect(CurrencyFormatter.format(10000), '₹10,000');
      expect(CurrencyFormatter.format(12500), '₹12,500');
      expect(CurrencyFormatter.format(100000), '₹1,00,000');
      expect(CurrencyFormatter.format(125000), '₹1,25,000');
      expect(CurrencyFormatter.format(1000000), '₹10,00,000');
    });

    test('formatAmountOnly produces Indian grouping without currency symbol', () {
      expect(CurrencyFormatter.formatAmountOnly(null), '0');
      expect(CurrencyFormatter.formatAmountOnly(0), '0');
      expect(CurrencyFormatter.formatAmountOnly(120), '120');
      expect(CurrencyFormatter.formatAmountOnly(125000), '1,25,000');
      expect(CurrencyFormatter.formatAmountOnly(149.50), '150');
    });

    test('formatPlain produces rounded integer string without formatting', () {
      expect(CurrencyFormatter.formatPlain(null), '0');
      expect(CurrencyFormatter.formatPlain(120.4), '120');
      expect(CurrencyFormatter.formatPlain(120.6), '121');
      expect(CurrencyFormatter.formatPlain(125000), '125000');
    });
  });
}
