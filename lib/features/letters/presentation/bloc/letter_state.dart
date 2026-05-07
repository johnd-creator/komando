import 'package:equatable/equatable.dart';

import '../../data/models/letter_model.dart';

sealed class LetterState extends Equatable {
  const LetterState();

  @override
  List<Object?> get props => [];
}

class LetterInitial extends LetterState {
  const LetterInitial();
}

class LetterLoading extends LetterState {
  const LetterLoading();
}

class LetterListLoaded extends LetterState {
  const LetterListLoaded({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    required this.box,
  });

  final List<LetterModel> items;
  final int currentPage;
  final bool hasMore;
  final String box;

  @override
  List<Object?> get props => [items, currentPage, hasMore, box];
}

class LetterDetailLoaded extends LetterState {
  const LetterDetailLoaded(this.letter);

  final LetterModel letter;

  @override
  List<Object?> get props => [letter];
}

class LetterCreateSuccess extends LetterState {
  const LetterCreateSuccess();
}

class LetterActionDone extends LetterState {
  const LetterActionDone();
}

class LetterCategoriesLoaded extends LetterState {
  const LetterCategoriesLoaded(this.categories);

  final List<LetterCategoryModel> categories;

  @override
  List<Object?> get props => [categories];
}

class LetterFailure extends LetterState {
  const LetterFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
