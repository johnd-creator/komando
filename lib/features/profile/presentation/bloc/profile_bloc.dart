import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository) : super(const ProfileInitial()) {
    on<ProfileRequested>(_onRequested);
  }

  final ProfileRepository _repository;

  Future<void> _onRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      emit(ProfileLoaded(await _repository.getProfile()));
    } catch (error) {
      emit(ProfileFailure(ApiErrorHandler.getMessage(error)));
    }
  }
}
