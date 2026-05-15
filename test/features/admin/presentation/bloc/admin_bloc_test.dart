import 'package:flutter_test/flutter_test.dart';
import 'package:komando/core/api/api_client.dart';
import 'package:komando/features/admin/data/models/admin_model.dart';
import 'package:komando/features/admin/data/repositories/admin_repository.dart';
import 'package:komando/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:komando/features/admin/presentation/bloc/admin_event.dart';
import 'package:komando/features/admin/presentation/bloc/admin_state.dart';

void main() {
  group('AdminBloc', () {
    test('AdminDashboardFetched emits loading then dashboard loaded', () async {
      final bloc = AdminBloc(_FakeAdminRepository());
      addTearDown(bloc.close);

      bloc.add(const AdminDashboardFetched());

      final loaded =
          await bloc.stream.firstWhere((state) => state is AdminDashboardLoaded)
              as AdminDashboardLoaded;

      expect(loaded.dashboard.totalMembers, 50);
      expect(loaded.dashboard.balance, 1000000);
      expect(loaded.dashboard.pendingOnboarding, 3);
    });

    test('AdminMembersFetched emits members with pagination', () async {
      final bloc = AdminBloc(_FakeAdminRepository());
      addTearDown(bloc.close);

      bloc.add(const AdminMembersFetched(page: 1));

      final firstPage =
          await bloc.stream.firstWhere((state) => state is AdminMembersLoaded)
              as AdminMembersLoaded;

      expect(firstPage.page.items, hasLength(20));
      expect(firstPage.page.currentPage, 1);
      expect(firstPage.page.hasMore, isTrue);

      // Load second page — should append
      bloc.add(const AdminMembersFetched(page: 2));

      final secondPage =
          await bloc.stream.firstWhere(
                (state) =>
                    state is AdminMembersLoaded && state.page.currentPage == 2,
              )
              as AdminMembersLoaded;

      expect(secondPage.page.items, hasLength(40));
      expect(secondPage.page.currentPage, 2);
    });

    test('AdminMemberDetailFetched emits member detail', () async {
      final bloc = AdminBloc(_FakeAdminRepository());
      addTearDown(bloc.close);

      bloc.add(const AdminMemberDetailFetched(5));

      final detail =
          await bloc.stream.firstWhere(
                (state) => state is AdminMemberDetailLoaded,
              )
              as AdminMemberDetailLoaded;

      expect(detail.member.id, 5);
      expect(detail.member.name, 'Anggota 5');
      expect(detail.member.npa, 'NPA-005');
    });

    test('AdminDashboardFetched emits failure on error', () async {
      final bloc = AdminBloc(_FailingAdminRepository());
      addTearDown(bloc.close);

      bloc.add(const AdminDashboardFetched());

      final failure =
          await bloc.stream.firstWhere((state) => state is AdminFailure)
              as AdminFailure;

      expect(failure.message, isNotEmpty);
    });
  });
}

class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository() : super(ApiClient());

  @override
  Future<AdminDashboardModel> getDashboard() async {
    return const AdminDashboardModel(
      totalMembers: 50,
      balance: 1000000,
      totalAspirations: 10,
      totalInboxLetters: 5,
      pendingLedgers: 2,
      pendingOnboarding: 3,
      pendingUpdates: 1,
      pendingMutations: 0,
      totalUnits: 4,
    );
  }

  @override
  Future<AdminMemberPageModel> getMembers({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final items = List.generate(perPage, (i) {
      final id = ((page - 1) * perPage) + i + 1;
      return AdminMemberModel(
        id: id,
        name: 'Anggota $id',
        npa: 'NPA-${id.toString().padLeft(3, '0')}',
        email: 'anggota$id@example.com',
        role: 'anggota',
        unitName: 'Unit ${(id % 4) + 1}',
        status: 'active',
      );
    });

    return AdminMemberPageModel(
      items: items,
      currentPage: page,
      lastPage: 3,
      total: 50,
    );
  }

  @override
  Future<AdminMemberModel> getMemberDetail(int id) async {
    return AdminMemberModel(
      id: id,
      name: 'Anggota $id',
      npa: 'NPA-${id.toString().padLeft(3, '0')}',
      email: 'anggota$id@example.com',
      role: 'anggota',
      unitName: 'Unit 1',
      status: 'active',
      phone: '08123456789',
      position: 'Anggota Biasa',
      joinedAt: '2024-01-15',
    );
  }

  @override
  Future<AdminMemberModel> updateMember(
    int id,
    Map<String, dynamic> data,
  ) async {
    return AdminMemberModel(
      id: id,
      name: data['name'] as String? ?? 'Anggota $id',
      npa: 'NPA-${id.toString().padLeft(3, '0')}',
      email: data['email'] as String? ?? 'anggota$id@example.com',
      role: 'anggota',
      unitName: 'Unit 1',
      status: 'active',
    );
  }
}

class _FailingAdminRepository extends AdminRepository {
  _FailingAdminRepository() : super(ApiClient());

  @override
  Future<AdminDashboardModel> getDashboard() async {
    throw Exception('Network error');
  }
}
