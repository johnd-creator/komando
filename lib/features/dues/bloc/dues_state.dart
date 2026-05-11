import 'package:equatable/equatable.dart';
import '../models/dues_payment.dart';
import '../models/dues_summary.dart';

enum DuesStatus { initial, loading, success, error }

class DuesState extends Equatable {
  final DuesStatus status;
  final bool hasMember;
  final List<DuesPayment> payments;
  final DuesSummary? summary;
  final double defaultAmount;
  final String? errorMessage;

  const DuesState({
    this.status = DuesStatus.initial,
    this.hasMember = false,
    this.payments = const [],
    this.summary,
    this.defaultAmount = 0.0,
    this.errorMessage,
  });

  DuesState copyWith({
    DuesStatus? status,
    bool? hasMember,
    List<DuesPayment>? payments,
    DuesSummary? summary,
    double? defaultAmount,
    String? errorMessage,
  }) {
    return DuesState(
      status: status ?? this.status,
      hasMember: hasMember ?? this.hasMember,
      payments: payments ?? this.payments,
      summary: summary ?? this.summary,
      defaultAmount: defaultAmount ?? this.defaultAmount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, hasMember, payments, summary, defaultAmount, errorMessage];
}
