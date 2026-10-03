/// Product-level purchase quantity rule (D-012), read from the product API.
///
/// min / max / step are configured per product by the admin, in the product's
/// unit. The backend validates every cart and order quantity; this class only
/// drives the +/- controls and early client-side feedback.
///
/// Products without a configuration keep the previous behaviour: start at 1,
/// change by 1, no configured maximum (unit precision still applies).
class QuantityRule {
  final String unit;
  final double min;
  final double? max;
  final double step;
  final bool isConfigured;

  const QuantityRule({
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.isConfigured,
  });

  /// Rule for a product without configured quantity values.
  const QuantityRule.unconfigured(this.unit)
      : min = 1,
        max = null,
        step = 1,
        isConfigured = false;

  /// Builds the rule from API values; falls back to [QuantityRule.unconfigured]
  /// unless all three values are present and positive.
  factory QuantityRule.fromValues({
    required String unit,
    double? min,
    double? max,
    double? step,
  }) {
    if (min == null || max == null || step == null || min <= 0 || max < min || step <= 0) {
      return QuantityRule.unconfigured(unit);
    }
    return QuantityRule(unit: unit, min: min, max: max, step: step, isConfigured: true);
  }

  /// Decimal places allowed for the unit (mirrors the backend).
  int get decimals {
    switch (unit.toUpperCase()) {
      case 'PIECE':
      case 'GRAM':
        return 0;
      default:
        return 3;
    }
  }

  static int _milli(double value) => (value * 1000).round();
  static double _fromMilli(int milli) => milli / 1000;

  /// Quantity after tapping "+" (or "ADD" when [current] is 0). Returns null
  /// when the maximum is already reached.
  double? next(double current) {
    if (current <= 0) return min;
    final candidate = _milli(current) + _milli(step);
    if (max != null && candidate > _milli(max!)) return null;
    return _fromMilli(candidate);
  }

  /// Quantity after tapping "−"; 0 means the line should be removed.
  double previous(double current) {
    final candidate = _milli(current) - _milli(step);
    if (candidate < _milli(min)) return 0;
    return _fromMilli(candidate);
  }

  bool canIncrement(double current) => next(current) != null;

  /// Returns a user-facing message when [quantity] breaks the rule, else null.
  String? validate(double quantity) {
    if (quantity <= 0) return 'Quantity must be greater than 0.';
    final milli = quantity * 1000;
    if ((milli - milli.round()).abs() > 1e-6) return 'Quantity has too many decimal places.';
    final allowedUnit = decimals == 0 ? 1000 : 1;
    if (_milli(quantity) % allowedUnit != 0) return 'Quantity must be a whole number of ${unitLabel(quantity)}.';
    if (!isConfigured) return null;
    if (_milli(quantity) < _milli(min)) return 'Minimum is ${formatWithUnit(min)}.';
    if (max != null && _milli(quantity) > _milli(max!)) return 'Maximum is ${formatWithUnit(max!)}.';
    if ((_milli(quantity) - _milli(min)) % _milli(step) != 0) {
      return 'Choose ${formatWithUnit(min)} plus steps of ${formatWithUnit(step)}.';
    }
    return null;
  }

  /// "1.25", "2", "250" — trailing zeros trimmed.
  static String format(double value) {
    final text = value.toStringAsFixed(3);
    return text.contains('.') ? text.replaceFirst(RegExp(r'\.?0+$'), '') : text;
  }

  String unitLabel(double value) {
    switch (unit.toUpperCase()) {
      case 'KG':
        return 'kg';
      case 'GRAM':
        return 'g';
      case 'PIECE':
        return value == 1 ? 'pc' : 'pcs';
      case 'PACK':
        return value == 1 ? 'pack' : 'packs';
      case 'DOZEN':
        return 'dozen';
      default:
        return unit.toLowerCase();
    }
  }

  /// "1.25 kg", "250 g", "2 pcs".
  String formatWithUnit(double value) => '${format(value)} ${unitLabel(value)}';

  /// "Min 1 kg · Max 10 kg · Step 0.25 kg" for configured products, else null.
  String? get limitsLabel {
    if (!isConfigured) return null;
    return 'Min ${formatWithUnit(min)} · Max ${formatWithUnit(max!)} · Step ${formatWithUnit(step)}';
  }
}
