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
      final dashboard = await _repository.getDashboard();
      final units = await _safeGetUnits(dashboard);
      final ledgerPage = await _safeGetLedgerPage(dashboard);

      emit(
        FinanceKeuanganLoaded(
          dashboard: dashboard,
          units: units,
          items: ledgerPage.items,
          currentPage: ledgerPage.currentPage,
          hasMore: ledgerPage.hasMore,
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

  Future<FinanceLedgerPageModel> _safeGetLedgerPage(
    FinanceDashboardModel dashboard,
  ) async {
    try {
      return await _repository.getLedgers(page: 1, perPage: _perPage);
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
      final ledgerPage = await _repository.getLedgers(
        page: 1,
        perPage: _perPage,
        type: event.filters['type'] as String?,
        status: event.filters['status'] as String?,
        unitId: event.filters['unit_id'] as int?,
      );

      emit(
        FinanceKeuanganLoaded(
          dashboard: currentState.dashboard,
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

  Future<void> _onFormRequested(
    FinanceLedgerFormRequested event,
    Emitter<FinanceState> emit,
  ) async {
    emit(const FinanceLoading(message: 'Memuat form...'));
    try {
      final categories = await _repository.getCategories();
      final units = await _repository.getUnits();

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
