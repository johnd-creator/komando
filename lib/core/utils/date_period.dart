import 'package:intl/intl.dart';

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

const _longMonths = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Formats a "YYYY-MM" period string to short form.
///
/// Example: `formatPeriod("2026-05")` → `"Mei 2026"`
String formatPeriod(String yyyyMM) {
  try {
    final parts = yyyyMM.split('-');
    if (parts.length == 2) {
      final m = int.parse(parts[1]);
      if (m >= 1 && m <= 12) {
        return '${_shortMonths[m - 1]} ${parts[0]}';
      }
    }
  } catch (_) {}
  return yyyyMM;
}

/// Formats a [DateTime] to long Indonesian month + year.
///
/// Example: `formatPeriodLong(DateTime(2026, 5))` → `"Mei 2026"`
String formatPeriodLong(DateTime date) {
  return '${_longMonths[date.month - 1]} ${date.year}';
}

/// Parses a "YYYY-MM" string to [DateTime], returns null on failure.
DateTime? parsePeriod(String yyyyMM) {
  try {
    return DateFormat('yyyy-MM').parse(yyyyMM);
  } catch (_) {
    return null;
  }
}
