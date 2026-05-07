import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../data/models/feedback_request.dart';
import '../../data/repositories/feedback_repository.dart';
import 'feedback_event.dart';
import 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  FeedbackBloc(this._repository) : super(const FeedbackInitial()) {
    on<FeedbackSubmitted>(_onSubmitted);
  }

  final FeedbackRepository _repository;

  Future<void> _onSubmitted(
    FeedbackSubmitted event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(const FeedbackSubmitting());
    try {
      await _repository.submit(
        FeedbackRequest(rating: event.rating, message: event.message),
      );
      emit(const FeedbackSubmittedSuccess());
    } catch (error) {
      emit(FeedbackFailure(ApiErrorHandler.getMessage(error)));
    }
  }
}
