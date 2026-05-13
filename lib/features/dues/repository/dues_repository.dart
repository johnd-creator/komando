import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/json_read.dart';
import '../models/dues_admin_summary.dart';
import '../models/dues_mass_update_item.dart';
import '../models/dues_payment.dart';
import '../models/dues_summary.dart';

class DuesRepository {
  final Dio _dio;

  DuesRepository(this._dio);

  Future<Map<String, dynamic>> getMyDues() async {
    final response = await _dio.get<Map<String, dynamic>>('/dues');
    final root = response.data ?? <String, dynamic>{};
    final data = _readDataMap(root);
    final payments = _readDataList(root, fallbackKey: 'payments');
    return {
      'hasMember': data['has_member'] ?? root['has_member'] ?? false,
      'payments': payments.map(DuesPayment.fromJson).toList(),
      'summary': _readNestedMap(root, key: 'summary') != null
          ? DuesSummary.fromJson(_readNestedMap(root, key: 'summary')!)
          : null,
      'defaultAmount':
          (data['default_amount'] as num?)?.toDouble() ??
          (root['default_amount'] as num?)?.toDouble() ??
          0.0,
    };
  }

  Future<Map<String, dynamic>> getAdminDues({
    String? period,
    String? status,
    String? memberId,
    String? unitId,
    String? query,
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (period != null) queryParameters['period'] = period;
    if (status != null) queryParameters['status'] = status;
    if (memberId != null) queryParameters['member_id'] = memberId;
    if (unitId != null) queryParameters['unit_id'] = unitId;
    if (query != null && query.trim().isNotEmpty) {
      queryParameters['q'] = query.trim();
    }

    debugPrint('[DuesRepo] GET /finance/dues params=$queryParameters');

    final response = await _dio.get<Map<String, dynamic>>(
      '/finance/dues',
      queryParameters: queryParameters,
    );

    final root = response.data ?? <String, dynamic>{};
    final items = _extractPaginatedList(root);
    final meta = _extractPaginationMeta(root);

    debugPrint('[DuesRepo] Parsed ${items.length} items, meta=$meta');

    return {
      'payments': items.map(DuesPayment.fromJson).toList(),
      'currentPage': meta['current_page'] ?? 1,
      'totalPages': meta['last_page'] ?? 1,
      'hasMore': (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1),
    };
  }

  Future<DuesAdminSummary> getAdminDuesSummary({
    String? period,
    String? unitId,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (period != null) queryParameters['period'] = period;
    if (unitId != null) queryParameters['unit_id'] = unitId;

    final response = await _dio.get<Map<String, dynamic>>(
      '/finance/dues/dashboard',
      queryParameters: queryParameters,
    );
    final root = response.data ?? <String, dynamic>{};
    final summary = _readNestedMap(root, key: 'summary') ?? _readDataMap(root);
    return DuesAdminSummary.fromJson(summary);
  }

  Future<DuesPayment> updateDuesPayment(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/finance/dues/$id',
      data: body,
    );
    final root = response.data ?? <String, dynamic>{};
    final item =
        _readNestedMap(root, key: 'payment') ??
        _readNestedMap(root, key: 'dues') ??
        _readDataMap(root);
    return DuesPayment.fromJson(item);
  }

  Future<int> massUpdateDues(List<DuesMassUpdateItem> items) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/finance/dues/mass-update',
      data: {'items': items.map((e) => e.toJson()).toList()},
    );
    final root = response.data ?? <String, dynamic>{};
    final data = _readDataMap(root);
    return readInt(data, const ['updated'], fallback: 0);
  }

  Future<Map<String, dynamic>> getDuesReport({String? unitId}) async {
    final queryParameters = <String, dynamic>{};
    if (unitId != null) queryParameters['unit_id'] = unitId;

    final response = await _dio.get<Map<String, dynamic>>(
      '/reports/dues',
      queryParameters: queryParameters,
    );
    final root = response.data ?? <String, dynamic>{};
    return _readDataMap(root);
  }

  List<Map<String, dynamic>> _extractPaginatedList(Map<String, dynamic> root) {
    final data = root['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList();
      }
      final dues = data['dues'];
      if (dues is List) {
        return dues.whereType<Map<String, dynamic>>().toList();
      }
      final payments = data['payments'];
      if (payments is List) {
        return payments.whereType<Map<String, dynamic>>().toList();
      }
      final items = data['items'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
    }

    for (final key in const ['dues', 'payments', 'items']) {
      final value = root[key];
      if (value is List) {
        return value.whereType<Map<String, dynamic>>().toList();
      }
    }

    return const [];
  }

  Map<String, int> _extractPaginationMeta(Map<String, dynamic> root) {
    final meta = root['meta'];
    if (meta is Map<String, dynamic>) {
      return {
        'current_page': _asInt(meta['current_page']) ?? 1,
        'last_page': _asInt(meta['last_page']) ?? 1,
      };
    }

    final data = root['data'];
    if (data is Map<String, dynamic>) {
      final nestedMeta = data['meta'];
      if (nestedMeta is Map<String, dynamic>) {
        return {
          'current_page': _asInt(nestedMeta['current_page']) ?? 1,
          'last_page':
              _asInt(nestedMeta['last_page']) ??
              _asInt(nestedMeta['total_pages']) ??
              1,
        };
      }

      return {
        'current_page': _asInt(data['current_page']) ?? 1,
        'last_page':
            _asInt(data['last_page']) ?? _asInt(data['total_pages']) ?? 1,
      };
    }

    return {
      'current_page': _asInt(root['current_page']) ?? 1,
      'last_page':
          _asInt(root['last_page']) ?? _asInt(root['total_pages']) ?? 1,
    };
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> _readDataMap(Map<String, dynamic> root) {
    final data = root['data'];
    if (data is Map<String, dynamic>) return data;
    return root;
  }

  List<Map<String, dynamic>> _readDataList(
    Map<String, dynamic> root, {
    String? fallbackKey,
  }) {
    final data = root['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (fallbackKey != null) {
      return readList(_readDataMap(root), fallbackKey);
    }
    return const [];
  }

  Map<String, dynamic>? _readNestedMap(
    Map<String, dynamic> root, {
    required String key,
  }) {
    final dataMap = _readDataMap(root);
    final nested = dataMap[key];
    if (nested is Map<String, dynamic>) return nested;
    final direct = root[key];
    if (direct is Map<String, dynamic>) return direct;
    return null;
  }
}
