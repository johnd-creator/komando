import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository) : super(const ProfileInitial()) {
    on<ProfileRequested>(_onRequested);
    on<ProfilePhotoUploaded>(_onPhotoUploaded);
    on<ProfilePhotoDeleted>(_onPhotoDeleted);
  }

  final ProfileRepository _repository;

  Future<void> _onRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final cached = await _repository.getCachedProfile();
    if (cached != null) {
      emit(ProfileLoaded(cached));
    } else {
      emit(const ProfileLoading());
    }

    try {
      emit(ProfileLoaded(await _repository.getProfile()));
    } catch (error) {
      if (cached == null) {
        emit(ProfileFailure(ApiErrorHandler.getMessage(error)));
      }
    }
  }

  Future<void> _onPhotoUploaded(
    ProfilePhotoUploaded event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final updated = await _repository.uploadPhoto(event.filePath);
      emit(ProfileLoaded(updated));
    } catch (error) {
      emit(ProfileFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> _onPhotoDeleted(
    ProfilePhotoDeleted event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final updated = await _repository.deletePhoto();
      emit(ProfileLoaded(updated));
    } catch (error) {
      emit(ProfileFailure(ApiErrorHandler.getMessage(error)));
    }
  }
}
