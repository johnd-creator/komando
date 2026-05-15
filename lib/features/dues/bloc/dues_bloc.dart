import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_error_handler.dart';
import '../repository/dues_repository.dart';
import 'dues_event.dart';
import 'dues_state.dart';

class DuesBloc extends Bloc<DuesEvent, DuesState> {
  final DuesRepository repository;

  DuesBloc({required this.repository}) : super(const DuesState()) {
    on<LoadMyDues>(_onLoadMyDues);
    on<RefreshMyDues>(_onRefreshMyDues);
  }

  Future<void> _onLoadMyDues(LoadMyDues event, Emitter<DuesState> emit) async {
    emit(state.copyWith(status: DuesStatus.loading));
    try {
      final result = await repository.getMyDues().timeout(
        const Duration(seconds: 20),
      );
      emit(
        state.copyWith(
          status: DuesStatus.success,
          hasMember: result.hasMember,
          payments: result.payments,
          summary: result.summary,
          defaultAmount: result.defaultAmount,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DuesStatus.error,
          errorMessage: ApiErrorHandler.getMessage(e),
        ),
      );
    }
  }

  Future<void> _onRefreshMyDues(
    RefreshMyDues event,
    Emitter<DuesState> emit,
  ) async {
    try {
      final result = await repository.getMyDues().timeout(
        const Duration(seconds: 20),
      );
      emit(
        state.copyWith(
          status: DuesStatus.success,
          hasMember: result.hasMember,
          payments: result.payments,
          summary: result.summary,
          defaultAmount: result.defaultAmount,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DuesStatus.error,
          errorMessage: ApiErrorHandler.getMessage(e),
        ),
      );
    }
  }
}
