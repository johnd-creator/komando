import '../../../../core/api/api_client.dart';
import '../models/feedback_request.dart';

class FeedbackRepository {
  const FeedbackRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> submit(FeedbackRequest feedback) async {
    await _apiClient.dio.post<void>('/feedback', data: feedback.toJson());
  }
}
