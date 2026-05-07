import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../data/repositories/announcement_repository.dart';
import 'announcement_event.dart';
import 'announcement_state.dart';

class AnnouncementBloc extends Bloc<AnnouncementEvent, AnnouncementState> {
  AnnouncementBloc(this._repository) : super(const AnnouncementInitial()) {
    on<AnnouncementsFetched>(_onFetched);
    on<AnnouncementDetailFetched>(_onDetailFetched);
    on<AnnouncementDismissRequested>(_onDismissRequested);
  }

  static const _perPage = 10;

  final AnnouncementRepository _repository;

  Future<void> _onFetched(
    AnnouncementsFetched event,
    Emitter<AnnouncementState> emit,
  ) async {
    final currentState = state;
    final isNextPage = currentState is AnnouncementListLoaded && !event.refresh;
    final nextPage = isNextPage ? currentState.currentPage + 1 : 1;

    if (isNextPage && !currentState.hasMore) {
      return;
    }

    if (!isNextPage) {
      emit(const AnnouncementLoading());
    }

    try {
      final page = await _repository.getAnnouncements(
        page: nextPage,
        perPage: _perPage,
        query: event.query ?? (isNextPage ? currentState.query : null),
      );
      final previousItems = isNextPage ? currentState.items : const [];
      emit(
        AnnouncementListLoaded(
          items: [...previousItems, ...page.items],
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          query: event.query ?? (isNextPage ? currentState.query : null),
        ),
      );
    } catch (error) {
      emit(AnnouncementFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onDetailFetched(
    AnnouncementDetailFetched event,
    Emitter<AnnouncementState> emit,
  ) async {
    emit(const AnnouncementLoading());
    try {
      emit(
        AnnouncementDetailLoaded(await _repository.getAnnouncement(event.id)),
      );
    } catch (error) {
      emit(AnnouncementFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onDismissRequested(
    AnnouncementDismissRequested event,
    Emitter<AnnouncementState> emit,
  ) async {
    try {
      await _repository.dismiss(event.id);
      add(const AnnouncementsFetched(refresh: true));
    } catch (error) {
      emit(AnnouncementFailure(ApiErrorHandler.getMessage(error)));
    }
  }
}
