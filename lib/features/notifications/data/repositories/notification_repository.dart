import '../../../../core/api/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  const NotificationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<NotificationPageModel> getNotifications({int perPage = 15}) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'per_page': perPage},
    );
    return NotificationPageModel.fromJson(response.data ?? {});
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.dio.post<void>('/notifications/$id/read');
  }
}
