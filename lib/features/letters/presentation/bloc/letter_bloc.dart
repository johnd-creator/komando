import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../data/repositories/letter_repository.dart';
import 'letter_event.dart';
import 'letter_state.dart';

class LetterBloc extends Bloc<LetterEvent, LetterState> {
  LetterBloc(this._repository) : super(const LetterInitial()) {
    on<LettersFetched>(_onFetched);
    on<LetterDetailFetched>(_onDetailFetched);
    on<LetterCreated>(_onCreated);
    on<LetterSubmitted>(_onSubmitted);
    on<LetterSent>(_onSent);
    on<LetterArchived>(_onArchived);
    on<LetterApproved>(_onApproved);
    on<LetterRejected>(_onRejected);
    on<LetterBoxChanged>(_onBoxChanged);
    on<LetterCategoriesFetched>(_onCategoriesFetched);
  }

  static const _perPage = 10;

  final LetterRepository _repository;

  Future<void> _onFetched(
    LettersFetched event,
    Emitter<LetterState> emit,
  ) async {
    final currentState = state;
    final isNextPage =
        currentState is LetterListLoaded &&
        !event.refresh &&
        currentState.box == event.box;
    final nextPage = isNextPage ? currentState.currentPage + 1 : 1;

    if (isNextPage && !currentState.hasMore) return;

    if (!isNextPage) emit(const LetterLoading());

    try {
      final page = await _repository.getLetters(
        box: event.box,
        page: nextPage,
        perPage: _perPage,
      );
      final previousItems = isNextPage ? currentState.items : const [];
      emit(
        LetterListLoaded(
          items: [...previousItems, ...page.items],
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          box: event.box,
        ),
      );
    } catch (error) {
      emit(LetterFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onDetailFetched(
    LetterDetailFetched event,
    Emitter<LetterState> emit,
  ) async {
    emit(const LetterLoading());
    try {
      emit(LetterDetailLoaded(await _repository.getLetter(event.id)));
    } catch (error) {
      emit(LetterFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onCreated(
    LetterCreated event,
    Emitter<LetterState> emit,
  ) async {
    emit(const LetterLoading());
    try {
      await _repository.createLetter(
        categoryId: event.categoryId,
        subject: event.subject,
        body: event.body,
      );
      emit(const LetterCreateSuccess());
    } catch (error) {
      emit(LetterFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onSubmitted(
    LetterSubmitted event,
    Emitter<LetterState> emit,
  ) async {
    try {
      await _repository.submitLetter(event.id);
      emit(const LetterActionDone());
      add(const LettersFetched(box: 'outbox', refresh: true));
    } catch (error) {
      emit(LetterFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onSent(
    LetterSent event,
    Emitter<LetterState> emit,
  ) async {
    try {
      await _repository.sendLetter(event.id);
      emit(const LetterActionDone());
      add(const LettersFetched(box: 'outbox', refresh: true));
    } catch (error) {
      emit(LetterFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onArchived(
    LetterArchived event,
    Emitter<LetterState> emit,
  ) async {
    try {
      await _repository.archiveLetter(event.id);
      emit(const LetterActionDone());
      add(const LettersFetched(box: 'inbox', refresh: true));
    } catch (error) {
      emit(LetterFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onApproved(
    LetterApproved event,
    Emitter<LetterState> emit,
  ) async {
    try {
      await _repository.approveLetter(event.id);
      emit(const LetterActionDone());
      add(const LettersFetched(box: 'approvals', refresh: true));
    } catch (error) {
      emit(LetterFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onRejected(
    LetterRejected event,
    Emitter<LetterState> emit,
  ) async {
    try {
      await _repository.rejectLetter(event.id);
      emit(const LetterActionDone());
      add(const LettersFetched(box: 'approvals', refresh: true));
    } catch (error) {
      emit(LetterFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onBoxChanged(
    LetterBoxChanged event,
    Emitter<LetterState> emit,
  ) async {
    add(LettersFetched(box: event.box, refresh: true));
  }

  Future<void> _onCategoriesFetched(
    LetterCategoriesFetched event,
    Emitter<LetterState> emit,
  ) async {
    try {
      emit(LetterCategoriesLoaded(await _repository.getCategories()));
    } catch (error) {
      emit(LetterFailure(ApiErrorHandler.getMessage(error)));
    }
  }
}
