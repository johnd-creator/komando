import 'package:equatable/equatable.dart';

sealed class AspirationEvent extends Equatable {
  const AspirationEvent();

  @override
  List<Object?> get props => [];
}

class AspirationsFetched extends AspirationEvent {
  const AspirationsFetched({
    this.category,
    this.status,
    this.sort,
    this.refresh = false,
  });

  final String? category;
  final String? status;
  final String? sort;
  final bool refresh;

  @override
  List<Object?> get props => [category, status, sort, refresh];
}

class AspirationDetailFetched extends AspirationEvent {
  const AspirationDetailFetched(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class AspirationCreated extends AspirationEvent {
  const AspirationCreated({
    required this.categoryId,
    required this.title,
    required this.body,
    this.tags = const [],
    this.isAnonymous = false,
  });

  final int categoryId;
  final String title;
  final String body;
  final List<String> tags;
  final bool isAnonymous;

  @override
  List<Object?> get props => [categoryId, title, body, tags, isAnonymous];
}

class AspirationSupportToggled extends AspirationEvent {
  const AspirationSupportToggled(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class AspirationCategoriesFetched extends AspirationEvent {
  const AspirationCategoriesFetched();
}

class AspirationTagsFetched extends AspirationEvent {
  const AspirationTagsFetched();
}
