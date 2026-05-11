import 'package:equatable/equatable.dart';

abstract class DuesEvent extends Equatable {
  const DuesEvent();

  @override
  List<Object> get props => [];
}

class LoadMyDues extends DuesEvent {}
class RefreshMyDues extends DuesEvent {}
