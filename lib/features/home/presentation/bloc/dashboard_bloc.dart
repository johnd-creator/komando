import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository) : super(const DashboardInitial()) {
    on<DashboardRequested>(_onRequested);
  }

  final DashboardRepository _repository;

  Future<void> _onRequested(
    DashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      emit(DashboardLoaded(await _repository.getDashboard()));
    } catch (error) {
      emit(DashboardFailure(ApiErrorHandler.getMessage(error)));
    }
  }
}
