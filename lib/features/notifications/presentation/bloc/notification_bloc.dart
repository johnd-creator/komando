import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(this._repository) : super(const NotificationInitial()) {
    on<NotificationsFetched>(_onFetched);
    on<NotificationReadRequested>(_onReadRequested);
  }

  final NotificationRepository _repository;

  Future<void> _onFetched(
    NotificationsFetched event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());
    try {
      emit(NotificationLoaded(await _repository.getNotifications()));
    } catch (error) {
      emit(NotificationFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onReadRequested(
    NotificationReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAsRead(event.id);
      emit(NotificationLoaded(await _repository.getNotifications()));
    } catch (error) {
      emit(NotificationFailure(ApiErrorHandler.getMessage(error)));
    }
  }
}
