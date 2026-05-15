import 'package:equatable/equatable.dart';
import '../models/dues_payment.dart';
import '../models/dues_admin_summary.dart';

enum DuesAdminStatus { initial, loading, success, error, loadingMore }

class DuesAdminState extends Equatable {
  final DuesAdminStatus status;
  final List<DuesPayment> payments;
  final DuesAdminSummary? summary;
  final Map<String, String> filters;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool canChecklist;
  final double defaultAmount;
  final String? errorMessage;

  const DuesAdminState({
    this.status = DuesAdminStatus.initial,
    this.payments = const [],
    this.summary,
    this.filters = const {},
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.canChecklist = false,
    this.defaultAmount = 50000,
    this.errorMessage,
  });

  DuesAdminState copyWith({
    DuesAdminStatus? status,
    List<DuesPayment>? payments,
    DuesAdminSummary? summary,
    Map<String, String>? filters,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool? canChecklist,
    double? defaultAmount,
    String? errorMessage,
  }) {
    return DuesAdminState(
      status: status ?? this.status,
      payments: payments ?? this.payments,
      summary: summary ?? this.summary,
      filters: filters ?? this.filters,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      canChecklist: canChecklist ?? this.canChecklist,
      defaultAmount: defaultAmount ?? this.defaultAmount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    payments,
    summary,
    filters,
    currentPage,
    totalPages,
    hasMore,
    canChecklist,
    defaultAmount,
    errorMessage,
  ];
}
