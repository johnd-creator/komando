import '../../../../core/api/api_client.dart';
import '../../../../core/api/json_read.dart';
import 'package:dio/dio.dart';
import '../models/dues_model.dart';
import '../models/finance_model.dart';

class FinanceRepository {
  const FinanceRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<DuesResponse> getDues() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/dues');
    return DuesResponse.fromJson(response.data ?? {});
  }

  Future<FinanceDashboardModel> getDashboard() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/finance/dashboard',
    );
    return FinanceDashboardModel.fromJson(response.data ?? {});
  }

  Future<FinanceLedgerPageModel> getLedgers({
    int page = 1,
    int perPage = 20,
    String? type,
    String? status,
    int? categoryId,
    int? unitId,
    String? from,
    String? to,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/finance/ledgers',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (type != null && type.isNotEmpty) 'type': type,
        if (status != null && status.isNotEmpty) 'status': status,
        'finance_category_id': ?categoryId,
        'unit_id': ?unitId,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );
    return FinanceLedgerPageModel.fromJson(response.data ?? {});
  }

  Future<FinanceUnitsResponse> getUnits() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/finance/units',
    );
    return FinanceUnitsResponse.fromJson(response.data ?? {});
  }

  Future<FinanceLedgerModel> createLedger({
    required String date,
    required int categoryId,
    required String type,
    required double amount,
    required String description,
    int? unitId,
    String? attachmentPath,
    String? attachmentName,
  }) async {
    final data = {
      'date': date,
      'finance_category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'organization_unit_id': ?unitId,
      if (attachmentPath != null && attachmentPath.isNotEmpty)
        'attachment': await MultipartFile.fromFile(
          attachmentPath,
          filename: attachmentName,
        ),
    };

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/finance/ledgers',
      data: FormData.fromMap(data),
    );
    return FinanceLedgerModel.fromJson(readMap(response.data ?? {}, 'ledger'));
  }

  Future<FinanceLedgerModel> updateLedger(
    int id, {
    String? date,
    int? categoryId,
    String? type,
    double? amount,
    String? description,
    int? unitId,
    String? attachmentPath,
    String? attachmentName,
  }) async {
    final data = <String, dynamic>{};
    if (date != null) data['date'] = date;
    if (categoryId != null) data['finance_category_id'] = categoryId;
    if (type != null) data['type'] = type;
    if (amount != null) data['amount'] = amount;
    if (description != null) data['description'] = description;
    if (unitId != null) data['organization_unit_id'] = unitId;
    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      data['attachment'] = await MultipartFile.fromFile(
        attachmentPath,
        filename: attachmentName,
      );
    }

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/finance/ledgers/$id',
      data: FormData.fromMap({...data, '_method': 'PUT'}),
    );
    return FinanceLedgerModel.fromJson(readMap(response.data ?? {}, 'ledger'));
  }

  Future<void> deleteLedger(int id) async {
    await _apiClient.dio.delete('/finance/ledgers/$id');
  }

  Future<void> approveLedger(int id) async {
    await _apiClient.dio.post('/finance/ledgers/$id/approve');
  }

  Future<void> rejectLedger(int id, String reason) async {
    await _apiClient.dio.post(
      '/finance/ledgers/$id/reject',
      data: {'reason': reason},
    );
  }

  Future<List<LedgerCategoryModel>> getCategories({String? type}) async {
    final query = <String, dynamic>{};
    if (type != null && type.isNotEmpty) query['type'] = type;

    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/finance/categories',
      queryParameters: query,
    );
    final categories = readList(
      response.data ?? {},
      'categories',
    ).map((e) => LedgerCategoryModel.fromJson(e)).toList();
    return categories;
  }
}
