import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/news_repository.dart';
import 'news_event.dart';
import 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  NewsBloc(this._repository) : super(const NewsInitial()) {
    on<NewsFetched>(_onFetched);
    on<NewsLoadMore>(_onLoadMore);
  }

  static const _perPage = 10;

  final NewsRepository _repository;

  Future<void> _onFetched(NewsFetched event, Emitter<NewsState> emit) async {
    final cached = await _repository.getCachedPosts();
    final hasCached = cached.isNotEmpty;
    if (hasCached) {
      emit(NewsLoaded(items: cached, page: 1, hasMore: true));
    } else {
      emit(const NewsLoading());
    }

    try {
      final items = await _repository.getPosts(page: 1, perPage: _perPage);
      emit(
        NewsLoaded(items: items, page: 1, hasMore: items.length >= _perPage),
      );
    } catch (error) {
      if (!hasCached) {
        emit(const NewsFailure('Gagal memuat berita.'));
      }
    }
  }

  Future<void> _onLoadMore(NewsLoadMore event, Emitter<NewsState> emit) async {
    if (state is! NewsLoaded) return;

    final current = state as NewsLoaded;
    if (!current.hasMore) return;

    try {
      final nextPage = current.page + 1;
      final items = await _repository.getPosts(
        page: nextPage,
        perPage: _perPage,
      );
      emit(
        NewsLoaded(
          items: [...current.items, ...items],
          page: nextPage,
          hasMore: items.length >= _perPage,
        ),
      );
    } catch (error) {
      emit(const NewsFailure('Gagal memuat berita tambahan.'));
    }
  }
}
