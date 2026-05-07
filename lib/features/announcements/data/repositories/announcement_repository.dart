import '../../../../core/api/api_client.dart';
import '../models/announcement_model.dart';

class AnnouncementRepository {
  const AnnouncementRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AnnouncementPageModel> getAnnouncements({
    int page = 1,
    int perPage = 10,
    String? query,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/announcements',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    return AnnouncementPageModel.fromJson(response.data ?? {});
  }

  Future<AnnouncementModel> getAnnouncement(int id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/announcements/$id',
    );
    final data = response.data ?? {};
    return AnnouncementModel.fromJson(
      data['announcement'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<void> dismiss(int id) async {
    await _apiClient.dio.post<void>('/announcements/$id/dismiss');
  }
}
