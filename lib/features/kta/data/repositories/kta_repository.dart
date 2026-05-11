import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/cache/app_cache.dart';
import '../models/kta_card_model.dart';

class KtaRepository {
  KtaRepository(this._apiClient, {AppCache? cache})
    : _cache = cache ?? AppCache();

  final ApiClient _apiClient;
  final AppCache _cache;

  Future<KtaCardModel?> getCachedCard() async {
    final cached = await _cache.readJson(AppCache.ktaCardKey);
    if (cached == null) return null;
    return KtaCardModel.fromCache(cached);
  }

  Future<Uint8List?> getCachedQrImage() {
    return _cache.readBytes(AppCache.ktaQrKey);
  }

  Future<KtaCardModel> getCard() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/member/card',
    );
    final card = KtaCardModel.fromJson(response.data ?? {});
    await _cache.writeJson(AppCache.ktaCardKey, card.toCache());
    return card;
  }

  Future<Uint8List> getQrImage() async {
    final response = await _apiClient.dio.get<List<int>>(
      '/member/card/qr',
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': 'image/png'},
      ),
    );
    final bytes = Uint8List.fromList(response.data ?? const []);
    await _cache.writeBytes(AppCache.ktaQrKey, bytes);
    return bytes;
  }
}
