import '../../../../core/api/api_client.dart';
import '../../../../core/api/json_read.dart';
import '../models/admin_model.dart';
import '../models/reports_model.dart';

class AdminRepository {
  const AdminRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AdminDashboardModel> getDashboard() async {
    final totalMembers = await _countFromPaginated(
      '/admin/members',
      queryParameters: const {'per_page': 1},
    );
    final pendingOnboarding = await _countFromPaginated(
      '/admin/onboarding',
      queryParameters: const {'status': 'pending', 'per_page': 1},
    );
    final pendingUpdates = await _countFromPaginated(
      '/admin/updates',
      queryParameters: const {'status': 'pending', 'per_page': 1},
    );
    final pendingMutations = await _countFromPaginated(
      '/admin/mutations',
      queryParameters: const {'status': 'pending', 'per_page': 1},
    );

    var pendingLedgers = 0;
    var totalDuesThisMonth = 0.0;
    try {
      final finance = await _apiClient.dio.get<Map<String, dynamic>>(
        '/finance/dashboard',
      );
      final summary = readMap(finance.data ?? {}, 'summary');
      pendingLedgers = readInt(summary, const ['pending_count']);
      totalDuesThisMonth =
          (summary['income_this_month'] as num?)?.toDouble() ?? 0;
    } catch (_) {
      // Some admin roles can manage members but cannot access finance.
    }

    return AdminDashboardModel(
      totalMembers: totalMembers,
      totalDuesThisMonth: totalDuesThisMonth,
      totalAspirations: 0,
      totalLetters: 0,
      pendingLedgers: pendingLedgers,
      pendingOnboarding: pendingOnboarding,
      pendingUpdates: pendingUpdates,
      pendingMutations: pendingMutations,
      totalUnits: 0,
    );
  }

  Future<int> _countFromPaginated(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return readInt(readMap(response.data ?? {}, 'meta'), const ['total']);
    } catch (_) {
      return 0;
    }
  }

  Future<AdminMemberPageModel> getMembers({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.isNotEmpty) query['q'] = search;

    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/admin/members',
      queryParameters: query,
    );
    final data = response.data ?? {};
    final items = readList(
      data,
      'members',
    ).map((e) => AdminMemberModel.fromJson(e)).toList();
    final meta = data['meta'] as Map<String, dynamic>? ?? {};

    return AdminMemberPageModel(
      items: items,
      currentPage: readInt(meta, const ['current_page'], fallback: 1),
      lastPage: readInt(meta, const ['last_page'], fallback: 1),
      total: readInt(meta, const ['total']),
    );
  }

  Future<AdminMemberModel> getMemberDetail(int id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/admin/members/$id',
    );
    return AdminMemberModel.fromJson(
      response.data?['member'] as Map<String, dynamic>? ??
          response.data?['data'] as Map<String, dynamic>? ??
          {},
    );
  }

  Future<AdminMemberModel> updateMember(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      '/admin/members/$id',
      data: data,
    );
    return AdminMemberModel.fromJson(
      response.data?['member'] as Map<String, dynamic>? ??
          response.data?['data'] as Map<String, dynamic>? ??
          {},
    );
  }

  Future<ExportRequest> requestExport(String type) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/reports/export',
      queryParameters: {'type': type},
    );
    return ExportRequest.fromJson(response.data ?? {});
  }

  Future<ExportRequest> checkExportStatus(String id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/reports/export/status/$id',
    );
    return ExportRequest.fromJson(response.data ?? {});
  }
}
