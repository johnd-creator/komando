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
    var balance = 0.0;
    try {
      final finance = await _apiClient.dio.get<Map<String, dynamic>>(
        '/finance/dashboard',
      );
      final summary = readMap(finance.data ?? {}, 'summary');
      pendingLedgers = readInt(summary, const ['pending_count']);
      balance = readDouble(summary, const ['balance']);
    } catch (_) {
      // Some admin roles can manage members but cannot access finance.
    }

    final totalAspirations = await _countFromPaginated(
      '/aspirations',
      queryParameters: const {'per_page': 1},
    );
    final totalInboxLetters = await _countFromPaginated(
      '/letters/inbox',
      queryParameters: const {'per_page': 1},
    );

    return AdminDashboardModel(
      totalMembers: totalMembers,
      balance: balance,
      totalAspirations: totalAspirations,
      totalInboxLetters: totalInboxLetters,
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
      return _readTotal(response.data ?? {});
    } catch (_) {
      return 0;
    }
  }

  int _readTotal(Map<String, dynamic> json) {
    final meta = readMap(json, 'meta');
    final metaTotal = readInt(meta, const ['total'], fallback: -1);
    if (metaTotal >= 0) return metaTotal;

    final data = readMap(json, 'data');
    final dataTotal = readInt(data, const ['total'], fallback: -1);
    if (dataTotal >= 0) return dataTotal;

    for (final key in const [
      'total',
      'count',
      'total_count',
      'aspirations_count',
      'letters_count',
      'members_count',
    ]) {
      final total = readInt(json, [key], fallback: -1);
      if (total >= 0) return total;
    }

    final rootList = _firstList(json);
    if (rootList != null) return rootList.length;

    final nestedList = data.isNotEmpty ? _firstList(data) : null;
    if (nestedList != null) return nestedList.length;

    return 0;
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
    final items = _readMembers(
      data,
    ).map((e) => AdminMemberModel.fromJson(e)).toList();
    final meta = readMap(data, 'meta').isNotEmpty
        ? readMap(data, 'meta')
        : readMap(readMap(data, 'data'), 'meta').isNotEmpty
        ? readMap(readMap(data, 'data'), 'meta')
        : readMap(data, 'data');

    return AdminMemberPageModel(
      items: items,
      currentPage: readInt(meta, const ['current_page'], fallback: 1),
      lastPage: readInt(meta, const ['last_page'], fallback: 1),
      total: readInt(meta, const ['total']),
    );
  }

  List<Map<String, dynamic>> _readMembers(Map<String, dynamic> json) {
    for (final source in [json, readMap(json, 'data')]) {
      for (final key in const ['members', 'data', 'items']) {
        final items = readList(source, key);
        if (items.isNotEmpty) return items;
      }
    }
    return const [];
  }

  List<Map<String, dynamic>>? _firstList(Map<String, dynamic> json) {
    for (final value in json.values) {
      if (value is List) {
        return value.whereType<Map<String, dynamic>>().toList();
      }
    }
    return null;
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
