import '../../../../core/api/api_client.dart';
import '../models/member_profile_model.dart';

class ProfileRepository {
  const ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<MemberProfileModel> getProfile() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/profile');
    return MemberProfileModel.fromJson(response.data ?? {});
  }
}
