import 'dues_payment.dart';
import 'dues_summary.dart';

/// Typed result from `DuesRepository.getMyDues`.
/// Replaces the untyped `Map<String, dynamic>` return value.
class MyDuesResult {
  const MyDuesResult({
    required this.hasMember,
    required this.payments,
    required this.defaultAmount,
    this.summary,
  });

  final bool hasMember;
  final List<DuesPayment> payments;
  final DuesSummary? summary;
  final double defaultAmount;

  MyDuesResult copyWith({
    bool? hasMember,
    List<DuesPayment>? payments,
    DuesSummary? summary,
    double? defaultAmount,
  }) {
    return MyDuesResult(
      hasMember: hasMember ?? this.hasMember,
      payments: payments ?? this.payments,
      summary: summary ?? this.summary,
      defaultAmount: defaultAmount ?? this.defaultAmount,
    );
  }
}
