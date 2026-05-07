import 'package:equatable/equatable.dart';

sealed class LetterEvent extends Equatable {
  const LetterEvent();

  @override
  List<Object?> get props => [];
}

class LettersFetched extends LetterEvent {
  const LettersFetched({required this.box, this.refresh = false});

  final String box;
  final bool refresh;

  @override
  List<Object?> get props => [box, refresh];
}

class LetterDetailFetched extends LetterEvent {
  const LetterDetailFetched(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class LetterCreated extends LetterEvent {
  const LetterCreated({
    required this.categoryId,
    required this.subject,
    required this.body,
  });

  final int categoryId;
  final String subject;
  final String body;

  @override
  List<Object?> get props => [categoryId, subject, body];
}

class LetterSubmitted extends LetterEvent {
  const LetterSubmitted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class LetterSent extends LetterEvent {
  const LetterSent(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class LetterArchived extends LetterEvent {
  const LetterArchived(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class LetterApproved extends LetterEvent {
  const LetterApproved(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class LetterRejected extends LetterEvent {
  const LetterRejected(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class LetterBoxChanged extends LetterEvent {
  const LetterBoxChanged(this.box);

  final String box;

  @override
  List<Object?> get props => [box];
}

class LetterCategoriesFetched extends LetterEvent {
  const LetterCategoriesFetched();
}
