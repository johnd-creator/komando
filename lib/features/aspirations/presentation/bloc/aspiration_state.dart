import 'package:equatable/equatable.dart';

import '../../data/models/aspiration_model.dart';

sealed class AspirationState extends Equatable {
  const AspirationState();

  @override
  List<Object?> get props => [];
}

class AspirationInitial extends AspirationState {
  const AspirationInitial();
}

class AspirationLoading extends AspirationState {
  const AspirationLoading();
}

class AspirationListLoaded extends AspirationState {
  const AspirationListLoaded({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    this.category,
    this.status,
    this.sort,
  });

  final List<AspirationModel> items;
  final int currentPage;
  final bool hasMore;
  final String? category;
  final String? status;
  final String? sort;

  @override
  List<Object?> get props => [
    items,
    currentPage,
    hasMore,
    category,
    status,
    sort,
  ];
}

class AspirationDetailLoaded extends AspirationState {
  const AspirationDetailLoaded(this.aspiration);

  final AspirationModel aspiration;

  @override
  List<Object?> get props => [aspiration];
}

class AspirationCreateSuccess extends AspirationState {
  const AspirationCreateSuccess();
}

class AspirationCategoriesLoaded extends AspirationState {
  const AspirationCategoriesLoaded(this.categories);

  final List<AspirationCategoryModel> categories;

  @override
  List<Object?> get props => [categories];
}

class AspirationTagsLoaded extends AspirationState {
  const AspirationTagsLoaded(this.tags);

  final List<AspirationTagModel> tags;

  @override
  List<Object?> get props => [tags];
}

class AspirationFailure extends AspirationState {
  const AspirationFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
