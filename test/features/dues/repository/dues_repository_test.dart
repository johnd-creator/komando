import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komando/features/dues/repository/dues_repository.dart';

void main() {
  group('DuesRepository', () {
    test('parses admin dues from root payments response', () async {
      final repository = DuesRepository(
        _dioReturning({
          'payments': [
            {
              'id': 1,
              'member_id': 10,
              'member_name': 'Anggota Satu',
              'period': '2026-05',
              'status': 'unpaid',
              'amount': 30000,
            },
          ],
          'meta': {'current_page': 1, 'last_page': 1},
        }),
      );

      final result = await repository.getAdminDues(period: '2026-05');

      expect(result['payments'], hasLength(1));
      expect(result['hasMore'], isFalse);
    });

    test('parses admin dues from nested payments response', () async {
      final repository = DuesRepository(
        _dioReturning({
          'data': {
            'payments': [
              {
                'id': 1,
                'member': {'id': 10, 'name': 'Anggota Satu'},
                'period': '2026-05',
                'status': 'paid',
                'amount': 30000,
              },
            ],
            'meta': {'current_page': 1, 'last_page': 2},
          },
        }),
      );

      final result = await repository.getAdminDues(period: '2026-05');

      expect(result['payments'], hasLength(1));
      expect(result['hasMore'], isTrue);
    });

    test('parses admin dues from mobile backend dues response', () async {
      final repository = DuesRepository(
        _dioReturning({
          'dues': [
            {
              'id': null,
              'member_id': 10,
              'member_name': 'Anggota Satu',
              'kta_number': 'KTA-001',
              'period': '2026-05',
              'status': 'unpaid',
              'amount': 0,
              'paid_at': null,
              'notes': null,
            },
          ],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 15,
            'total': 1,
          },
        }),
      );

      final result = await repository.getAdminDues(period: '2026-05');

      expect(result['payments'], hasLength(1));
      expect(result['payments'].first.period, '2026-05');
      expect(result['payments'].first.memberName, 'Anggota Satu');
      expect(result['payments'].first.ktaNumber, 'KTA-001');
      expect(result['hasMore'], isFalse);
    });
  });
}

Dio _dioReturning(Map<String, dynamic> body) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<Map<String, dynamic>>(
            data: body,
            requestOptions: options,
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return dio;
}
