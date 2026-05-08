import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../data/repositories/aspiration_repository.dart';
import 'aspiration_event.dart';
import 'aspiration_state.dart';

class AspirationBloc extends Bloc<AspirationEvent, AspirationState> {
  AspirationBloc(this._repository) : super(const AspirationInitial()) {
    on<AspirationsFetched>(_onFetched);
    on<AspirationDetailFetched>(_onDetailFetched);
    on<AspirationCreated>(_onCreated);
    on<AspirationSupportToggled>(_onSupportToggled);
    on<AspirationCategoriesFetched>(_onCategoriesFetched);
    on<AspirationTagsFetched>(_onTagsFetched);
  }

  static const _perPage = 10;

  final AspirationRepository _repository;

  Future<void> _onFetched(
    AspirationsFetched event,
    Emitter<AspirationState> emit,
  ) async {
    final currentState = state;
    final isNextPage = currentState is AspirationListLoaded && !event.refresh;
    final nextPage = isNextPage ? currentState.currentPage + 1 : 1;

    if (isNextPage && !currentState.hasMore) {
      return;
    }

    if (!isNextPage) {
      emit(const AspirationLoading());
    }

    try {
      final page = await _repository.getAspirations(
        page: nextPage,
        perPage: _perPage,
        category: event.category ?? (isNextPage ? currentState.category : null),
        status: event.status ?? (isNextPage ? currentState.status : null),
        sort: event.sort ?? (isNextPage ? currentState.sort : null),
      );
      final previousItems = isNextPage ? currentState.items : const [];
      emit(
        AspirationListLoaded(
          items: [...previousItems, ...page.items],
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          category:
              event.category ?? (isNextPage ? currentState.category : null),
          status: event.status ?? (isNextPage ? currentState.status : null),
          sort: event.sort ?? (isNextPage ? currentState.sort : null),
        ),
      );
    } catch (error) {
      emit(AspirationFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onDetailFetched(
    AspirationDetailFetched event,
    Emitter<AspirationState> emit,
  ) async {
    emit(const AspirationLoading());
    try {
      emit(AspirationDetailLoaded(await _repository.getAspiration(event.id)));
    } catch (error) {
      emit(AspirationFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onCreated(
    AspirationCreated event,
    Emitter<AspirationState> emit,
  ) async {
    emit(const AspirationLoading());
    try {
      await _repository.createAspiration(
        categoryId: event.categoryId,
        title: event.title,
        body: event.body,
        tags: event.tags,
        isAnonymous: event.isAnonymous,
      );
      emit(const AspirationCreateSuccess());
    } catch (error) {
      emit(AspirationFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onSupportToggled(
    AspirationSupportToggled event,
    Emitter<AspirationState> emit,
  ) async {
    try {
      if (state is AspirationDetailLoaded) {
        final current = (state as AspirationDetailLoaded).aspiration;
        if (current.isSupported) {
          await _repository.unsupport(event.id);
        } else {
          await _repository.support(event.id);
        }
        add(AspirationDetailFetched(event.id));
      }
    } catch (error) {
      emit(AspirationFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onCategoriesFetched(
    AspirationCategoriesFetched event,
    Emitter<AspirationState> emit,
  ) async {
    try {
      emit(AspirationCategoriesLoaded(await _repository.getCategories()));
    } catch (error) {
      emit(AspirationFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onTagsFetched(
    AspirationTagsFetched event,
    Emitter<AspirationState> emit,
  ) async {
    try {
      emit(AspirationTagsLoaded(await _repository.getTags()));
    } catch (error) {
      emit(AspirationFailure(ApiErrorHandler.getMessage(error)));
    }
  }
}
