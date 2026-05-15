import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/cache/app_cache.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/member_profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient, {AppCache? cache})
    : _cache = cache ?? AppCache();

  final ApiClient _apiClient;
  final AppCache _cache;

  Future<MemberProfileModel?> getCachedProfile() async {
    // Return null if cache is stale (>30 min) so caller fetches fresh data
    if (await _cache.isStale(
      AppCache.profileKey,
      const Duration(minutes: 30),
    )) {
      return null;
    }
    final cached = await _cache.readJson(AppCache.profileKey);
    if (cached == null) return null;
    return MemberProfileModel.fromCache(cached);
  }

  Future<MemberProfileModel> getProfile() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/profile');
    AppLogger.api(
      'GET',
      '/profile',
      statusCode: response.statusCode,
      tag: 'ProfileRepo',
    );
    final rawData = response.data ?? {};
    final profile = MemberProfileModel.fromJson(rawData);
    // Do not log photoUrl or personal data — PII
    await _cache.writeJson(AppCache.profileKey, profile.toCache());
    return profile;
  }

  Future<MemberProfileModel> uploadPhoto(String filePath) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
    });
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/profile/photo',
      data: formData,
    );
    AppLogger.api(
      'POST',
      '/profile/photo',
      statusCode: response.statusCode,
      tag: 'ProfileRepo',
    );
    final rawData = response.data ?? {};
    final updated = MemberProfileModel.fromJson(rawData);
    // Do not log photoUrl or personal data — PII
    await _cache.writeJson(AppCache.profileKey, updated.toCache());
    return updated;
  }

  Future<MemberProfileModel> deletePhoto() async {
    final response = await _apiClient.dio.delete<Map<String, dynamic>>(
      '/profile/photo',
    );
    final updated = MemberProfileModel.fromJson(response.data ?? {});
    await _cache.writeJson(AppCache.profileKey, updated.toCache());
    return updated;
  }
}
