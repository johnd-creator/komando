import 'package:intl/intl.dart';

/// Formats [amount] as Indonesian Rupiah.
///
/// Examples:
/// - `formatRupiah(50000)` → `"Rp 50.000"`
/// - `formatRupiah(50000, showPrefix: false)` → `"50.000"`
String formatRupiah(double amount, {bool showPrefix = true}) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: showPrefix ? 'Rp ' : '',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

/// Formats [amount] in compact form (e.g. "50rb" for 50000).
String formatRupiahCompact(double amount) {
  if (amount >= 1000000) {
    return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
  }
  if (amount >= 1000) {
    return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
  }
  return formatRupiah(amount);
}
