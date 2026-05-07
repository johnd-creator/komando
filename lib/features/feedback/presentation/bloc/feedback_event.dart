import 'package:equatable/equatable.dart';

sealed class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

class FeedbackSubmitted extends FeedbackEvent {
  const FeedbackSubmitted({required this.rating, required this.message});

  final int rating;
  final String message;

  @override
  List<Object?> get props => [rating, message];
}
