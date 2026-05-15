import 'package:flutter_test/flutter_test.dart';
import 'package:komando/core/api/api_client.dart';
import 'package:komando/features/finance/data/models/dues_model.dart';
import 'package:komando/features/finance/data/models/finance_model.dart';
import 'package:komando/features/finance/data/repositories/finance_repository.dart';
import 'package:komando/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:komando/features/finance/presentation/bloc/finance_event.dart';
import 'package:komando/features/finance/presentation/bloc/finance_state.dart';

void main() {
  group('FinanceBloc', () {
    test(
      'FinanceKeuanganRequested emits loading then loaded with dashboard',
      () async {
        final bloc = FinanceBloc(_FakeFinanceRepository());
        addTearDown(bloc.close);

        bloc.add(const FinanceKeuanganRequested());

        final loaded =
            await bloc.stream.firstWhere(
                  (state) => state is FinanceKeuanganLoaded,
                )
                as FinanceKeuanganLoaded;

        expect(loaded.dashboard.summary.balance, 1000000);
        expect(loaded.dashboard.summary.incomeThisMonth, 500000);
        expect(loaded.items, hasLength(5));
        expect(loaded.hasMore, isFalse);
      },
    );

    test('FinanceKeuanganRequested emits failure on error', () async {
      final bloc = FinanceBloc(_FailingFinanceRepository());
      addTearDown(bloc.close);

      bloc.add(const FinanceKeuanganRequested());

      final failure =
          await bloc.stream.firstWhere((state) => state is FinanceFailure)
              as FinanceFailure;

      expect(failure.message, isNotEmpty);
    });

    test(
      'FinanceKeuanganFiltersChanged returns filtered ledger items',
      () async {
        final bloc = FinanceBloc(_FakeFinanceRepository());
        addTearDown(bloc.close);

        // First load the keuangan screen
        bloc.add(const FinanceKeuanganRequested());
        await bloc.stream.firstWhere((state) => state is FinanceKeuanganLoaded);

        // Then apply filters
        bloc.add(const FinanceKeuanganFiltersChanged({'type': 'income'}));

        final filtered =
            await bloc.stream.firstWhere(
                  (state) =>
                      state is FinanceKeuanganLoaded &&
                      state.filters.containsKey('type'),
                )
                as FinanceKeuanganLoaded;

        expect(filtered.items, hasLength(5));
        expect(filtered.filters['type'], 'income');
      },
    );

    test('FinanceDuesFetched emits loading then dues loaded', () async {
      final bloc = FinanceBloc(_FakeFinanceRepository());
      addTearDown(bloc.close);

      bloc.add(const FinanceDuesFetched());

      final loaded =
          await bloc.stream.firstWhere((state) => state is FinanceDuesLoaded)
              as FinanceDuesLoaded;

      expect(loaded.response.items, hasLength(3));
      expect(loaded.response.hasMember, isTrue);
    });
  });
}

class _FakeFinanceRepository extends FinanceRepository {
  _FakeFinanceRepository() : super(ApiClient());

  @override
  Future<DuesResponse> getDues() async {
    return DuesResponse(
      hasMember: true,
      items: List.generate(
        3,
        (i) => DueModel(
          id: i + 1,
          period: '2025-0${i + 1}',
          status: i == 0 ? 'paid' : 'unpaid',
          amount: 50000,
        ),
      ),
      summary: const DuesSummary(
        totalMonths: 3,
        paidCount: 1,
        unpaidCount: 2,
        totalAmount: 150000,
        paidAmount: 50000,
        currentPeriod: '2025-01',
        currentStatus: 'unpaid',
      ),
    );
  }

  @override
  Future<FinanceDashboardModel> getDashboard({int? unitId}) async {
    return FinanceDashboardModel(
      summary: const DashboardSummary(
        balance: 1000000,
        incomeThisMonth: 500000,
        expenseThisMonth: 200000,
        pendingCount: 2,
      ),
      recentTransactions: _generateLedgers(5),
      userRole: const UserRoleInfo(
        role: 'bendahara',
        unitId: 1,
        canViewGlobal: false,
      ),
    );
  }

  @override
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
    final items = _generateLedgers(5);
    return FinanceLedgerPageModel(
      items: items,
      currentPage: page,
      lastPage: 1,
      total: items.length,
    );
  }

  @override
  Future<FinanceUnitsResponse> getUnits() async {
    return const FinanceUnitsResponse(
      units: [
        FinanceUnitModel(id: 1, name: 'Unit A', code: 'UA', isPusat: true),
        FinanceUnitModel(id: 2, name: 'Unit B', code: 'UB', isPusat: false),
      ],
      accessibleCount: 2,
      role: 'bendahara',
    );
  }

  @override
  Future<List<LedgerCategoryModel>> getCategories({String? type}) async {
    return const [
      LedgerCategoryModel(id: 1, name: 'Iuran', type: 'income'),
      LedgerCategoryModel(id: 2, name: 'Operasional', type: 'expense'),
    ];
  }

  List<FinanceLedgerModel> _generateLedgers(int count) {
    return List.generate(
      count,
      (i) => FinanceLedgerModel(
        id: i + 1,
        date: '2025-01-${(i + 1).toString().padLeft(2, '0')}',
        type: i.isEven ? 'income' : 'expense',
        amount: 100000.0 * (i + 1),
        description: 'Transaksi ${i + 1}',
        status: 'approved',
        category: const LedgerCategory(id: 1, name: 'Iuran'),
      ),
    );
  }
}

class _FailingFinanceRepository extends FinanceRepository {
  _FailingFinanceRepository() : super(ApiClient());

  @override
  Future<FinanceDashboardModel> getDashboard({int? unitId}) async {
    throw Exception('Network error');
  }

  @override
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
    throw Exception('Network error');
  }

  @override
  Future<FinanceUnitsResponse> getUnits() async {
    throw Exception('Network error');
  }
}
