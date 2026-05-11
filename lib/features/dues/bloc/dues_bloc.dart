import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
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
      final data = await repository.getMyDues();
      emit(state.copyWith(
        status: DuesStatus.success,
        hasMember: data['hasMember'],
        payments: data['payments'],
        summary: data['summary'],
        defaultAmount: data['defaultAmount'],
        errorMessage: null,
      ));
    } catch (e) {
      String message = 'Terjadi kesalahan sistem';
      if (e is DioException && e.response != null) {
        message = e.response?.data['message'] ?? message;
      } else if (e is Exception) {
        message = e.toString();
      }
      emit(state.copyWith(status: DuesStatus.error, errorMessage: message));
    }
  }

  Future<void> _onRefreshMyDues(RefreshMyDues event, Emitter<DuesState> emit) async {
    try {
      final data = await repository.getMyDues();
      emit(state.copyWith(
        status: DuesStatus.success,
        hasMember: data['hasMember'],
        payments: data['payments'],
        summary: data['summary'],
        defaultAmount: data['defaultAmount'],
        errorMessage: null,
      ));
    } catch (e) {
      String message = 'Terjadi kesalahan saat memuat ulang';
      if (e is DioException && e.response != null) {
        message = e.response?.data['message'] ?? message;
      }
      emit(state.copyWith(status: DuesStatus.error, errorMessage: message));
    }
  }
}
