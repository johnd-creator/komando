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
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/profile');
    final profile = MemberProfileModel.fromJson(response.data ?? {});
    await _cache.writeJson(AppCache.profileKey, profile.toCache());
    return profile;
  }
}
