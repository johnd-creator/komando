import 'package:equatable/equatable.dart';

import '../../data/models/announcement_model.dart';

sealed class AnnouncementState extends Equatable {
  const AnnouncementState();

  @override
  List<Object?> get props => [];
}

class AnnouncementInitial extends AnnouncementState {
  const AnnouncementInitial();
}

class AnnouncementLoading extends AnnouncementState {
  const AnnouncementLoading();
}

class AnnouncementListLoaded extends AnnouncementState {
  const AnnouncementListLoaded({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    this.query,
  });

  final List<AnnouncementModel> items;
  final int currentPage;
  final bool hasMore;
  final String? query;

  @override
  List<Object?> get props => [items, currentPage, hasMore, query];
}

class AnnouncementDetailLoaded extends AnnouncementState {
  const AnnouncementDetailLoaded(this.announcement);

  final AnnouncementModel announcement;

  @override
  List<Object?> get props => [announcement];
}

class AnnouncementFailure extends AnnouncementState {
  const AnnouncementFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
