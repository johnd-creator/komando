import 'package:equatable/equatable.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

class ProfilePhotoUploaded extends ProfileEvent {
  const ProfilePhotoUploaded(this.filePath);

  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

class ProfilePhotoDeleted extends ProfileEvent {
  const ProfilePhotoDeleted();
}
