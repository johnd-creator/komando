import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../data/repositories/kta_repository.dart';
import 'kta_event.dart';
import 'kta_state.dart';

class KtaBloc extends Bloc<KtaEvent, KtaState> {
  KtaBloc(this._repository) : super(const KtaInitial()) {
    on<KtaCardRequested>(_onRequested);
  }

  final KtaRepository _repository;

  Future<void> _onRequested(
    KtaCardRequested event,
    Emitter<KtaState> emit,
  ) async {
    emit(const KtaLoading());
    try {
      final card = await _repository.getCard();
      final qrBytes = card.hasQr ? await _repository.getQrImage() : null;
      emit(KtaLoaded(card: card, qrBytes: qrBytes));
    } catch (error) {
      emit(KtaFailure(ApiErrorHandler.getMessage(error)));
    }
  }
}
