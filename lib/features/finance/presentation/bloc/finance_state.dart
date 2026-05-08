import 'package:equatable/equatable.dart';

import '../../data/models/dues_model.dart';
import '../../data/models/finance_model.dart';

sealed class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {
  const FinanceInitial();
}

class FinanceLoading extends FinanceState {
  const FinanceLoading({this.message = 'Memuat data keuangan...'});

  final String message;

  @override
  List<Object?> get props => [message];
}

class FinanceDuesLoaded extends FinanceState {
  const FinanceDuesLoaded({required this.response});

  final DuesResponse response;

  @override
  List<Object?> get props => [response];
}

class FinanceDashboardLoaded extends FinanceState {
  const FinanceDashboardLoaded({required this.dashboard});

  final FinanceDashboardModel dashboard;

  @override
  List<Object?> get props => [dashboard];
}

class FinanceLedgersLoaded extends FinanceState {
  const FinanceLedgersLoaded({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    this.filters = const {},
  });

  final List<FinanceLedgerModel> items;
  final int currentPage;
  final bool hasMore;
  final Map<String, dynamic> filters;

  @override
  List<Object?> get props => [items, currentPage, hasMore, filters];
}

class FinanceUnitsLoaded extends FinanceState {
  const FinanceUnitsLoaded({required this.response});

  final FinanceUnitsResponse response;

  @override
  List<Object?> get props => [response];
}

class FinanceKeuanganLoaded extends FinanceState {
  const FinanceKeuanganLoaded({
    required this.dashboard,
    required this.units,
    required this.items,
    required this.currentPage,
    required this.hasMore,
    this.filters = const {},
  });

  final FinanceDashboardModel dashboard;
  final FinanceUnitsResponse units;
  final List<FinanceLedgerModel> items;
  final int currentPage;
  final bool hasMore;
  final Map<String, dynamic> filters;

  @override
  List<Object?> get props => [
    dashboard,
    units,
    items,
    currentPage,
    hasMore,
    filters,
  ];
}

class FinanceFailure extends FinanceState {
  const FinanceFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class FinanceFormLoaded extends FinanceState {
  const FinanceFormLoaded({
    required this.categories,
    required this.units,
    this.ledger,
  });

  final List<LedgerCategoryModel> categories;
  final FinanceUnitsResponse units;
  final FinanceLedgerModel? ledger;

  bool get isEditMode => ledger != null;

  @override
  List<Object?> get props => [categories, units, ledger];
}

class FinanceFormSubmitting extends FinanceState {
  const FinanceFormSubmitting();
}

class FinanceFormSuccess extends FinanceState {
  const FinanceFormSuccess({required this.isEdit});

  final bool isEdit;

  @override
  List<Object?> get props => [isEdit];
}

class FinanceFormFailure extends FinanceState {
  const FinanceFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class FinanceLedgerDetailLoaded extends FinanceState {
  const FinanceLedgerDetailLoaded({
    required this.ledger,
    required this.userRole,
  });

  final FinanceLedgerModel ledger;
  final UserRoleInfo userRole;

  @override
  List<Object?> get props => [ledger, userRole];
}

class FinanceActionSuccess extends FinanceState {
  const FinanceActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class FinanceActionFailure extends FinanceState {
  const FinanceActionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
