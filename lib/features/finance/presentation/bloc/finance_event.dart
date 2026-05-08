import 'package:equatable/equatable.dart';

sealed class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

class FinanceDuesFetched extends FinanceEvent {
  const FinanceDuesFetched();
}

class FinanceDashboardFetched extends FinanceEvent {
  const FinanceDashboardFetched();
}

class FinanceLedgersFetched extends FinanceEvent {
  const FinanceLedgersFetched({this.filters = const {}, this.refresh = false});

  final Map<String, dynamic> filters;
  final bool refresh;

  @override
  List<Object?> get props => [filters, refresh];
}

class FinanceUnitsFetched extends FinanceEvent {
  const FinanceUnitsFetched();
}

class FinanceKeuanganRequested extends FinanceEvent {
  const FinanceKeuanganRequested();
}

class FinanceKeuanganFiltersChanged extends FinanceEvent {
  const FinanceKeuanganFiltersChanged(this.filters);

  final Map<String, dynamic> filters;

  @override
  List<Object?> get props => [filters];
}

class FinanceLedgerFormRequested extends FinanceEvent {
  const FinanceLedgerFormRequested({this.editId});

  final int? editId;

  @override
  List<Object?> get props => [editId];
}

class FinanceLedgerCreated extends FinanceEvent {
  const FinanceLedgerCreated({
    required this.date,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.description,
    this.unitId,
  });

  final String date;
  final int categoryId;
  final String type;
  final double amount;
  final String description;
  final int? unitId;

  @override
  List<Object?> get props => [
    date,
    categoryId,
    type,
    amount,
    description,
    unitId,
  ];
}

class FinanceLedgerUpdated extends FinanceEvent {
  const FinanceLedgerUpdated({
    required this.id,
    this.date,
    this.categoryId,
    this.type,
    this.amount,
    this.description,
    this.unitId,
  });

  final int id;
  final String? date;
  final int? categoryId;
  final String? type;
  final double? amount;
  final String? description;
  final int? unitId;

  @override
  List<Object?> get props => [
    id,
    date,
    categoryId,
    type,
    amount,
    description,
    unitId,
  ];
}

class FinanceLedgerDeleted extends FinanceEvent {
  const FinanceLedgerDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class FinanceLedgerApproved extends FinanceEvent {
  const FinanceLedgerApproved(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class FinanceLedgerRejected extends FinanceEvent {
  const FinanceLedgerRejected({required this.id, required this.reason});

  final int id;
  final String reason;

  @override
  List<Object?> get props => [id, reason];
}

class FinanceLedgerDetailFetched extends FinanceEvent {
  const FinanceLedgerDetailFetched(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
