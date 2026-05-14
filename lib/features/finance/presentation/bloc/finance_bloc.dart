import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../data/models/finance_model.dart';
import '../../data/repositories/finance_repository.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  FinanceBloc(this._repository) : super(const FinanceInitial()) {
    on<FinanceDuesFetched>(_onDuesFetched);
    on<FinanceKeuanganRequested>(_onKeuanganRequested);
    on<FinanceKeuanganFiltersChanged>(_onKeuanganFiltersChanged);
    on<FinanceLedgerFormRequested>(_onFormRequested);
    on<FinanceLedgerCreated>(_onCreated);
    on<FinanceLedgerUpdated>(_onUpdated);
    on<FinanceLedgerDeleted>(_onDeleted);
    on<FinanceLedgerApproved>(_onApproved);
    on<FinanceLedgerRejected>(_onRejected);
    on<FinanceLedgerDetailFetched>(_onDetailFetched);
  }

  static const _perPage = 20;

  final FinanceRepository _repository;

  Future<void> _onDuesFetched(
    FinanceDuesFetched event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading(message: 'Memuat data iuran...'));
    try {
      final response = await _repository.getDues();
      emit(FinanceDuesLoaded(response: response));
    } catch (error) {
      emit(FinanceFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onKeuanganRequested(
    FinanceKeuanganRequested event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading(message: 'Memuat data keuangan...'));
    try {
      final initialDashboard = await _repository.getDashboard();
      final units = await _safeGetUnits(initialDashboard);
      final defaultUnitId = _defaultFinanceUnitId(initialDashboard, units);
      final dashboard = defaultUnitId == null
          ? initialDashboard
          : await _safeGetDashboard(unitId: defaultUnitId);
      final ledgerPage = await _safeGetLedgerPage(
        dashboard,
        unitId: defaultUnitId,
      );
      final filters = <String, dynamic>{'unit_id': ?defaultUnitId};

      emit(
        FinanceKeuanganLoaded(
          dashboard: dashboard,
          units: units,
          items: ledgerPage.items,
          currentPage: ledgerPage.currentPage,
          hasMore: ledgerPage.hasMore,
          filters: filters,
        ),
      );
    } catch (error) {
      emit(FinanceFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<FinanceUnitsResponse> _safeGetUnits(
    FinanceDashboardModel dashboard,
  ) async {
    try {
      return await _repository.getUnits();
    } catch (_) {
      return FinanceUnitsResponse(
        units: const [],
        accessibleCount: 0,
        role: dashboard.userRole.role,
      );
    }
  }

  Future<FinanceDashboardModel> _safeGetDashboard({int? unitId}) async {
    try {
      return await _repository.getDashboard(unitId: unitId);
    } catch (_) {
      return await _repository.getDashboard();
    }
  }

  int? _defaultFinanceUnitId(
    FinanceDashboardModel dashboard,
    FinanceUnitsResponse units,
  ) {
    final role = dashboard.userRole.normalizedRole;

    if (role == 'bendahara_pusat') {
      final pusatUnits = units.units.where((unit) => unit.isPusat);
      if (pusatUnits.isNotEmpty) return pusatUnits.first.id;
    }

    if (role == 'bendahara' &&
        dashboard.userRole.unitId != null &&
        dashboard.userRole.unitId! > 0) {
      return dashboard.userRole.unitId;
    }

    return null;
  }

  Future<FinanceLedgerPageModel> _safeGetLedgerPage(
    FinanceDashboardModel dashboard, {
    int? unitId,
  }) async {
    try {
      return await _repository.getLedgers(
        page: 1,
        perPage: _perPage,
        unitId: unitId,
      );
    } catch (_) {
      return FinanceLedgerPageModel(
        items: dashboard.recentTransactions,
        currentPage: 1,
        lastPage: 1,
        total: dashboard.recentTransactions.length,
      );
    }
  }

  Future<void> _onKeuanganFiltersChanged(
    FinanceKeuanganFiltersChanged event,
    Emitter<FinanceState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FinanceKeuanganLoaded) return;

    emit(const FinanceLoading(message: 'Memuat transaksi...'));

    try {
      final unitId = _readUnitId(event.filters['unit_id']);
      final previousUnitId = _readUnitId(currentState.filters['unit_id']);
      final unitChanged = previousUnitId != unitId;
      final dashboard = unitChanged
          ? await _safeGetDashboard(unitId: unitId)
          : currentState.dashboard;
      final ledgerPage = await _repository.getLedgers(
        page: 1,
        perPage: _perPage,
        type: event.filters['type'] as String?,
        status: event.filters['status'] as String?,
        unitId: unitId,
      );
      final scopedDashboard =
          unitChanged &&
              unitId != null &&
              _sameSummary(dashboard.summary, currentState.dashboard.summary)
          ? await _dashboardFromVisibleUnitTransactions(dashboard, unitId)
          : dashboard;

      emit(
        FinanceKeuanganLoaded(
          dashboard: scopedDashboard,
          units: currentState.units,
          items: ledgerPage.items,
          currentPage: ledgerPage.currentPage,
          hasMore: ledgerPage.hasMore,
          filters: event.filters,
        ),
      );
    } catch (error) {
      emit(FinanceFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  int? _readUnitId(Object? value) {
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.toInt();
    return null;
  }

  bool _sameSummary(DashboardSummary a, DashboardSummary b) {
    return a.balance == b.balance &&
        a.incomeThisMonth == b.incomeThisMonth &&
        a.expenseThisMonth == b.expenseThisMonth &&
        a.pendingCount == b.pendingCount;
  }

  Future<FinanceDashboardModel> _dashboardFromVisibleUnitTransactions(
    FinanceDashboardModel dashboard,
    int unitId,
  ) async {
    try {
      final page = await _repository.getLedgers(
        page: 1,
        perPage: 100,
        unitId: unitId,
      );
      return FinanceDashboardModel(
        summary: _summaryFromLedgers(page.items),
        recentTransactions: dashboard.recentTransactions,
        userRole: dashboard.userRole,
      );
    } catch (_) {
      return FinanceDashboardModel(
        summary: const DashboardSummary(
          balance: 0,
          incomeThisMonth: 0,
          expenseThisMonth: 0,
          pendingCount: 0,
        ),
        recentTransactions: dashboard.recentTransactions,
        userRole: dashboard.userRole,
      );
    }
  }

  DashboardSummary _summaryFromLedgers(List<FinanceLedgerModel> items) {
    final now = DateTime.now();
    final currentMonth =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    var balance = 0.0;
    var incomeThisMonth = 0.0;
    var expenseThisMonth = 0.0;
    var pendingCount = 0;

    for (final item in items) {
      if (item.status == 'submitted') pendingCount += 1;
      if (item.status != 'approved') continue;

      final signedAmount = item.type == 'income' ? item.amount : -item.amount;
      balance += signedAmount;

      if (item.date.startsWith(currentMonth)) {
        if (item.type == 'income') {
          incomeThisMonth += item.amount;
        } else {
          expenseThisMonth += item.amount;
        }
      }
    }

    return DashboardSummary(
      balance: balance,
      incomeThisMonth: incomeThisMonth,
      expenseThisMonth: expenseThisMonth,
      pendingCount: pendingCount,
    );
  }

  Future<void> _onFormRequested(
    FinanceLedgerFormRequested event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading(message: 'Memuat form...'));
    try {
      final categories = await _repository.getCategories();
      final dashboard = await _repository.getDashboard();
      final units = await _safeGetUnits(dashboard);

      FinanceLedgerModel? ledger;
      if (event.editId != null) {
        final page = await _repository.getLedgers(
          page: 1,
          perPage: 100,
          status: null,
        );
        ledger = page.items
            .where((item) => item.id == event.editId)
            .firstOrNull;
      }

      emit(
        FinanceFormLoaded(categories: categories, units: units, ledger: ledger),
      );
    } catch (error) {
      emit(FinanceFormFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onCreated(
    FinanceLedgerCreated event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceFormSubmitting());
    try {
      await _repository.createLedger(
        date: event.date,
        categoryId: event.categoryId,
        type: event.type,
        amount: event.amount,
        description: event.description,
        unitId: event.unitId,
        attachmentPath: event.attachmentPath,
        attachmentName: event.attachmentName,
      );
      emit(const FinanceFormSuccess(isEdit: false));
    } catch (error) {
      emit(FinanceFormFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onUpdated(
    FinanceLedgerUpdated event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceFormSubmitting());
    try {
      await _repository.updateLedger(
        event.id,
        date: event.date,
        categoryId: event.categoryId,
        type: event.type,
        amount: event.amount,
        description: event.description,
        unitId: event.unitId,
        attachmentPath: event.attachmentPath,
        attachmentName: event.attachmentName,
      );
      emit(const FinanceFormSuccess(isEdit: true));
    } catch (error) {
      emit(FinanceFormFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onDeleted(
    FinanceLedgerDeleted event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading(message: 'Menghapus transaksi...'));
    try {
      await _repository.deleteLedger(event.id);
      emit(const FinanceActionSuccess('Transaksi berhasil dihapus'));
    } catch (error) {
      emit(FinanceActionFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onApproved(
    FinanceLedgerApproved event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading(message: 'Menyetujui transaksi...'));
    try {
      await _repository.approveLedger(event.id);
      emit(const FinanceActionSuccess('Transaksi berhasil disetujui'));
    } catch (error) {
      emit(FinanceActionFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onRejected(
    FinanceLedgerRejected event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading(message: 'Menolak transaksi...'));
    try {
      await _repository.rejectLedger(event.id, event.reason);
      emit(const FinanceActionSuccess('Transaksi berhasil ditolak'));
    } catch (error) {
      emit(FinanceActionFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onDetailFetched(
    FinanceLedgerDetailFetched event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading(message: 'Memuat detail transaksi...'));
    try {
      final dashboard = await _repository.getDashboard();
      final page = await _repository.getLedgers(page: 1, perPage: 100);
      final ledger = page.items.firstWhere((e) => e.id == event.id);
      emit(
        FinanceLedgerDetailLoaded(ledger: ledger, userRole: dashboard.userRole),
      );
    } catch (error) {
      emit(FinanceActionFailure(ApiErrorHandler.getMessage(error)));
    }
  }
}
