import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komando/features/dues/bloc/dues_admin_bloc.dart';
import 'package:komando/features/dues/bloc/dues_admin_event.dart';
import 'package:komando/features/dues/bloc/dues_admin_state.dart';
import 'package:komando/features/dues/models/dues_admin_summary.dart';
import 'package:komando/features/dues/models/dues_payment.dart';
import 'package:komando/features/dues/repository/dues_repository.dart';

void main() {
  group('DuesAdminBloc', () {
    test('appends typed payments when loading more pages', () async {
      final bloc = DuesAdminBloc(repository: _FakeDuesRepository());
      addTearDown(bloc.close);

      bloc.add(
        const LoadAdminDues(
          initialFilters: {'period': '2026-04', 'unit_id': '10'},
        ),
      );

      final firstPage = await bloc.stream.firstWhere(
        (state) =>
            state.status == DuesAdminStatus.success && state.currentPage == 1,
      );
      expect(firstPage.payments, hasLength(15));
      expect(firstPage.hasMore, isTrue);

      bloc.add(LoadMoreAdminDues());

      final secondPage = await bloc.stream.firstWhere(
        (state) =>
            state.status == DuesAdminStatus.success && state.currentPage == 2,
      );
      expect(secondPage.payments, hasLength(30));
      expect(secondPage.payments, everyElement(isA<DuesPayment>()));
    });
  });
}

class _FakeDuesRepository extends DuesRepository {
  _FakeDuesRepository() : super(Dio());

  @override
  Future<Map<String, dynamic>> getAdminDues({
    String? period,
    String? status,
    String? memberId,
    String? unitId,
    String? query,
    int page = 1,
    int perPage = 15,
  }) async {
    return {
      'payments': List<DuesPayment>.generate(perPage, (index) {
        final memberId = ((page - 1) * perPage) + index + 1;
        return DuesPayment(
          memberId: memberId,
          memberName: 'Anggota $memberId',
          ktaNumber: 'KTA-$memberId',
          period: period ?? '2026-04',
          status: 'unpaid',
          amount: 0,
        );
      }),
      'currentPage': page,
      'totalPages': 9,
      'hasMore': page < 9,
    };
  }

  @override
  Future<DuesAdminSummary> getAdminDuesSummary({
    String? period,
    String? unitId,
  }) async {
    return const DuesAdminSummary(
      paid: 1,
      unpaid: 134,
      waived: 0,
      totalAmount: 30000,
    );
  }
}
