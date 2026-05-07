import 'package:equatable/equatable.dart';

import '../../data/models/news_model.dart';

sealed class NewsState extends Equatable {
  const NewsState();

  @override
  List<Object?> get props => [];
}

class NewsInitial extends NewsState {
  const NewsInitial();
}

class NewsLoading extends NewsState {
  const NewsLoading();
}

class NewsLoaded extends NewsState {
  const NewsLoaded({
    required this.items,
    required this.hasMore,
    this.page = 1,
  });

  final List<NewsModel> items;
  final int page;
  final bool hasMore;

  @override
  List<Object?> get props => [items, page, hasMore];
}

class NewsFailure extends NewsState {
  const NewsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
