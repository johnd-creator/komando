import 'package:equatable/equatable.dart';

import '../../data/models/notification_model.dart';

sealed class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  const NotificationLoaded(this.page);

  final NotificationPageModel page;

  @override
  List<Object?> get props => [page];
}

class NotificationFailure extends NotificationState {
  const NotificationFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
