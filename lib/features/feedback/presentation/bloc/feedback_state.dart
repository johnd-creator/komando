import 'package:equatable/equatable.dart';

sealed class FeedbackState extends Equatable {
  const FeedbackState();

  @override
  List<Object?> get props => [];
}

class FeedbackInitial extends FeedbackState {
  const FeedbackInitial();
}

class FeedbackSubmitting extends FeedbackState {
  const FeedbackSubmitting();
}

class FeedbackSubmittedSuccess extends FeedbackState {
  const FeedbackSubmittedSuccess();
}

class FeedbackFailure extends FeedbackState {
  const FeedbackFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
