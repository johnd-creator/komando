import 'package:equatable/equatable.dart';

sealed class NewsEvent extends Equatable {
  const NewsEvent();

  @override
  List<Object?> get props => [];
}

class NewsFetched extends NewsEvent {
  const NewsFetched({this.refresh = false});

  final bool refresh;
}

class NewsLoadMore extends NewsEvent {
  const NewsLoadMore();
}
