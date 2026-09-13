import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _dateFormat.format(dateTime.toLocal());
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _timeFormat.format(dateTime.toLocal());
  }

  static String formatIso(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final parsed = DateTime.parse(isoString);
      return formatDateTime(parsed);
    } catch (_) {
      return isoString;
    }
  }
}
