import 'package:dio/dio.dart';
import '../models/dues_payment.dart';
import '../models/dues_summary.dart';
import '../models/dues_admin_summary.dart';
import '../models/dues_mass_update_item.dart';

class DuesRepository {
  final Dio _dio;

  DuesRepository(this._dio);

  Future<Map<String, dynamic>> getMyDues() async {
    final response = await _dio.get('/dues');
    final data = response.data['data'];
    return {
      'hasMember': data['has_member'] ?? false,
      'payments':
          (data['payments'] as List?)
              ?.map((e) => DuesPayment.fromJson(e))
              .toList() ??
          [],
      'summary': data['summary'] != null
          ? DuesSummary.fromJson(data['summary'])
          : null,
      'defaultAmount': (data['default_amount'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<Map<String, dynamic>> getAdminDues({
    String? period,
    String? status,
    String? memberId,
    String? unitId,
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _dio.get(
      '/finance/dues',
      queryParameters: {
        'period': ?period,
        'status': ?status,
        'member_id': ?memberId,
        'unit_id': ?unitId,
        'page': page,
        'per_page': perPage,
      },
    );

    final data = response.data['data'];
    final meta = response.data['meta'];

    return {
      'payments': (data as List).map((e) => DuesPayment.fromJson(e)).toList(),
      'currentPage': meta['current_page'],
      'totalPages': meta['last_page'],
      'hasMore': meta['current_page'] < meta['last_page'],
    };
  }

  Future<DuesAdminSummary> getAdminDuesSummary({
    String? period,
    String? unitId,
  }) async {
    final response = await _dio.get(
      '/finance/dues/dashboard',
      queryParameters: {'period': ?period, 'unit_id': ?unitId},
    );
    return DuesAdminSummary.fromJson(response.data['data']['summary']);
  }

  Future<DuesPayment> updateDuesPayment(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch('/finance/dues/$id', data: body);
    return DuesPayment.fromJson(response.data['data']);
  }

  Future<int> massUpdateDues(List<DuesMassUpdateItem> items) async {
    final response = await _dio.patch(
      '/finance/dues/mass-update',
      data: {'items': items.map((e) => e.toJson()).toList()},
    );
    return response.data['data']['updated'] ?? 0;
  }

  Future<Map<String, dynamic>> getDuesReport({String? unitId}) async {
    final response = await _dio.get(
      '/reports/dues',
      queryParameters: {'unit_id': ?unitId},
    );
    return response.data['data'];
  }
}
