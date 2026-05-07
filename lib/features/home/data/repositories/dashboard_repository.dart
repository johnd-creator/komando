import '../../../../core/api/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  const DashboardRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardModel> getDashboard() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/dashboard',
    );
    return DashboardModel.fromJson(response.data ?? {});
  }
}
