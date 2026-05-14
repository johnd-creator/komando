import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/cache/app_cache.dart';
import '../../../profile/data/models/member_profile_model.dart';
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
    final card = await _mergeProfileData(
      KtaCardModel.fromJson(response.data ?? {}),
    );
    await _cache.writeJson(AppCache.ktaCardKey, card.toCache());
    return card;
  }

  Future<KtaCardModel> _mergeProfileData(KtaCardModel card) async {
    try {
      final cachedProfile = await _cache.readJson(AppCache.profileKey);
      final profile = cachedProfile == null
          ? await _getProfileFromApi()
          : MemberProfileModel.fromCache(cachedProfile);

      return card.copyWith(
        name: _prefer(profile.name, card.name),
        number: _prefer(profile.memberNumber, card.number),
        status: _prefer(profile.status, card.status),
        unit: _prefer(profile.unit, card.unit),
        jobTitle: _prefer(
          profile.unionPosition,
          profile.jobTitle,
          card.jobTitle,
        ),
        photoUrl: profile.photoUrl ?? card.photoUrl,
      );
    } catch (_) {
      return card;
    }
  }

  Future<MemberProfileModel> _getProfileFromApi() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/profile');
    final profile = MemberProfileModel.fromJson(response.data ?? {});
    await _cache.writeJson(AppCache.profileKey, profile.toCache());
    return profile;
  }

  String _prefer(String first, String second, [String? third]) {
    if (first.trim().isNotEmpty && first != '-') return first;
    if (second.trim().isNotEmpty && second != '-') return second;
    return third ?? second;
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
