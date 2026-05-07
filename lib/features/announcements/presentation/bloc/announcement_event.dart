import 'package:equatable/equatable.dart';

sealed class AnnouncementEvent extends Equatable {
  const AnnouncementEvent();

  @override
  List<Object?> get props => [];
}

class AnnouncementsFetched extends AnnouncementEvent {
  const AnnouncementsFetched({this.query, this.refresh = false});

  final String? query;
  final bool refresh;

  @override
  List<Object?> get props => [query, refresh];
}

class AnnouncementDetailFetched extends AnnouncementEvent {
  const AnnouncementDetailFetched(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class AnnouncementDismissRequested extends AnnouncementEvent {
  const AnnouncementDismissRequested(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
