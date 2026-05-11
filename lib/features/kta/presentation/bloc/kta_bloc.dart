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
    final cachedCard = await _repository.getCachedCard();
    final cachedQrBytes = await _repository.getCachedQrImage();
    if (cachedCard != null) {
      emit(KtaLoaded(card: cachedCard, qrBytes: cachedQrBytes));
    } else {
      emit(const KtaLoading());
    }

    try {
      final card = await _repository.getCard();
      final qrBytes = card.hasQr ? await _repository.getQrImage() : null;
      emit(KtaLoaded(card: card, qrBytes: qrBytes));
    } catch (error) {
      if (cachedCard == null) {
        emit(KtaFailure(ApiErrorHandler.getMessage(error)));
      }
    }
  }
}
