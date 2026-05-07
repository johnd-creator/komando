import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../data/models/kta_card_model.dart';

sealed class KtaState extends Equatable {
  const KtaState();

  @override
  List<Object?> get props => [];
}

class KtaInitial extends KtaState {
  const KtaInitial();
}

class KtaLoading extends KtaState {
  const KtaLoading();
}

class KtaLoaded extends KtaState {
  const KtaLoaded({required this.card, this.qrBytes});

  final KtaCardModel card;
  final Uint8List? qrBytes;

  @override
  List<Object?> get props => [card, qrBytes];
}

class KtaFailure extends KtaState {
  const KtaFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
