import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_error_handler.dart';
import '../../../core/logging/app_logger.dart';
import '../repository/dues_repository.dart';
import 'dues_admin_event.dart';
import 'dues_admin_state.dart';
import '../models/dues_admin_summary.dart';
import '../models/dues_payment.dart';

class DuesAdminBloc extends Bloc<DuesAdminEvent, DuesAdminState> {
  final DuesRepository repository;

  DuesAdminBloc({required this.repository}) : super(const DuesAdminState()) {
    on<LoadAdminDues>(_onLoadAdminDues);
    on<LoadMoreAdminDues>(_onLoadMoreAdminDues);
    on<UpdateFilter>(_onUpdateFilter);
    on<UpdateDuesPayment>(_onUpdateDuesPayment);
    on<MassUpdateDues>(_onMassUpdateDues);
  }

  Future<void> _onLoadAdminDues(
    LoadAdminDues event,
    Emitter<DuesAdminState> emit,
  ) async {
    final filters = event.initialFilters != null
        ? (Map<String, String>.from(state.filters)
            ..addAll(event.initialFilters!))
        : state.filters;
    emit(
      state.copyWith(
        status: DuesAdminStatus.loading,
        canChecklist: event.canChecklist,
        filters: filters,
      ),
    );
    await _fetchData(emit, filters, 1);
  }

  Future<void> _onLoadMoreAdminDues(
    LoadMoreAdminDues event,
    Emitter<DuesAdminState> emit,
  ) async {
    if (state.hasMore && state.status != DuesAdminStatus.loadingMore) {
      emit(state.copyWith(status: DuesAdminStatus.loadingMore));
      await _fetchData(
        emit,
        state.filters,
        state.currentPage + 1,
        append: true,
      );
    }
  }

  Future<void> _onUpdateFilter(
    UpdateFilter event,
    Emitter<DuesAdminState> emit,
  ) async {
    final newFilters = Map<String, String>.from(state.filters)
      ..addAll(event.filters);
    emit(
      state.copyWith(
        status: DuesAdminStatus.loading,
        filters: newFilters,
        payments: [],
        hasMore: false,
      ),
    );
    await _fetchData(emit, newFilters, 1);
  }

  Future<void> _onUpdateDuesPayment(
    UpdateDuesPayment event,
    Emitter<DuesAdminState> emit,
  ) async {
    try {
      await repository.updateDuesPayment(event.id, event.body);
      emit(state.copyWith(status: DuesAdminStatus.loading));
      await _fetchData(emit, state.filters, 1);
    } catch (e) {
      final message = ApiErrorHandler.getMessage(e);
      emit(
        state.copyWith(status: DuesAdminStatus.error, errorMessage: message),
      );
    }
  }

  Future<void> _onMassUpdateDues(
    MassUpdateDues event,
    Emitter<DuesAdminState> emit,
  ) async {
    try {
      await repository.massUpdateDues(event.items);
      emit(state.copyWith(status: DuesAdminStatus.loading));
      await _fetchData(emit, state.filters, 1);
    } catch (e) {
      final message = ApiErrorHandler.getMessage(e);
      emit(
        state.copyWith(status: DuesAdminStatus.error, errorMessage: message),
      );
    }
  }

  Future<void> _fetchData(
    Emitter<DuesAdminState> emit,
    Map<String, String> filters,
    int page, {
    bool append = false,
  }) async {
    try {
      AppLogger.d('_fetchData page=$page', tag: 'DuesAdminBloc');

      final data = await repository
          .getAdminDues(
            period: filters['period'],
            status: filters['status'],
            memberId: filters['member_id'],
            unitId: filters['unit_id'],
            query: filters['q'],
            page: page,
          )
          .timeout(const Duration(seconds: 20));

      final payments = List<DuesPayment>.from(data['payments'] as List);

      AppLogger.d('Received ${payments.length} payments', tag: 'DuesAdminBloc');

      DuesAdminSummary? summary;
      try {
        summary = await repository
            .getAdminDuesSummary(
              period: filters['period'],
              unitId: filters['unit_id'],
            )
            .timeout(const Duration(seconds: 12));
      } catch (summaryErr) {
        AppLogger.w('Summary fetch failed: $summaryErr', tag: 'DuesAdminBloc');
        summary =
            state.summary ??
            const DuesAdminSummary(
              paid: 0,
              unpaid: 0,
              waived: 0,
              totalAmount: 0,
            );
      }

      // Cache defaultAmount — only fetch from API if not yet loaded in state
      final defaultAmount = state.defaultAmount > 0
          ? state.defaultAmount
          : (await repository.getDefaultDuesAmount() ??
                DuesRepository.fallbackDuesAmount);

      final newPayments = append
          ? <DuesPayment>[...state.payments, ...payments]
          : payments;

      emit(
        state.copyWith(
          status: DuesAdminStatus.success,
          payments: newPayments,
          summary: summary,
          currentPage: data['currentPage'] as int,
          totalPages: data['totalPages'] as int,
          hasMore: data['hasMore'] as bool,
          defaultAmount: defaultAmount,
          errorMessage: null,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        '_fetchData failed',
        error: e,
        stack: stackTrace,
        tag: 'DuesAdminBloc',
      );
      final message = e is DioException
          ? ApiErrorHandler.getMessage(e)
          : 'Data iuran gagal dimuat: ${e.runtimeType}';
      emit(
        state.copyWith(status: DuesAdminStatus.error, errorMessage: message),
      );
    }
  }
}
