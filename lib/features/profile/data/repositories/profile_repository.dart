import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/cache/app_cache.dart';
import '../models/member_profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient, {AppCache? cache})
    : _cache = cache ?? AppCache();

  final ApiClient _apiClient;
  final AppCache _cache;

  Future<MemberProfileModel?> getCachedProfile() async {
    final cached = await _cache.readJson(AppCache.profileKey);
    if (cached == null) return null;
    return MemberProfileModel.fromCache(cached);
  }

  Future<MemberProfileModel> getProfile() async {
    final response =
        await _apiClient.dio.get<Map<String, dynamic>>('/profile');
    final rawData = response.data ?? {};
    debugPrint('[ProfileRepo] GET /profile raw: $rawData');
    final profile = MemberProfileModel.fromJson(rawData);
    debugPrint('[ProfileRepo] parsed photoUrl: ${profile.photoUrl}');
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
    final rawData = response.data ?? {};
    debugPrint('[ProfileRepo] POST /profile/photo raw: $rawData');
    final updated = MemberProfileModel.fromJson(rawData);
    debugPrint('[ProfileRepo] upload parsed photoUrl: ${updated.photoUrl}');
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
