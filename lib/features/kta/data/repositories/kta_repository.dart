import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/kta_card_model.dart';

class KtaRepository {
  const KtaRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<KtaCardModel> getCard() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/member/card',
    );
    return KtaCardModel.fromJson(response.data ?? {});
  }

  Future<Uint8List> getQrImage() async {
    final response = await _apiClient.dio.get<List<int>>(
      '/member/card/qr',
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': 'image/png'},
      ),
    );
    return Uint8List.fromList(response.data ?? const []);
  }
}
