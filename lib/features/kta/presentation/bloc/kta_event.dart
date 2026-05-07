import 'package:equatable/equatable.dart';

sealed class KtaEvent extends Equatable {
  const KtaEvent();

  @override
  List<Object?> get props => [];
}

class KtaCardRequested extends KtaEvent {
  const KtaCardRequested();
}
