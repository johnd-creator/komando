import 'package:equatable/equatable.dart';
import '../models/dues_mass_update_item.dart';

abstract class DuesAdminEvent extends Equatable {
  const DuesAdminEvent();

  @override
  List<Object> get props => [];
}

class LoadAdminDues extends DuesAdminEvent {
  final bool canChecklist;
  final Map<String, String>? initialFilters;
  const LoadAdminDues({this.canChecklist = false, this.initialFilters});

  @override
  List<Object> get props => [canChecklist, initialFilters ?? {}];
}

class LoadMoreAdminDues extends DuesAdminEvent {}

class UpdateFilter extends DuesAdminEvent {
  final Map<String, String> filters;
  const UpdateFilter(this.filters);

  @override
  List<Object> get props => [filters];
}

class UpdateDuesPayment extends DuesAdminEvent {
  final int id;
  final Map<String, dynamic> body;

  const UpdateDuesPayment(this.id, this.body);

  @override
  List<Object> get props => [id, body];
}

class MassUpdateDues extends DuesAdminEvent {
  final List<DuesMassUpdateItem> items;

  const MassUpdateDues(this.items);

  @override
  List<Object> get props => [items];
}
