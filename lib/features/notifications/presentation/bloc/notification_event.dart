import 'package:equatable/equatable.dart';

sealed class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsFetched extends NotificationEvent {
  const NotificationsFetched();
}

class NotificationReadRequested extends NotificationEvent {
  const NotificationReadRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class NotificationsReadAllRequested extends NotificationEvent {
  const NotificationsReadAllRequested();
}
