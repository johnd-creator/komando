import '../../../../core/api/json_read.dart';

class AdminDashboardModel {
  const AdminDashboardModel({
    required this.totalMembers,
    required this.totalDuesThisMonth,
    required this.totalAspirations,
    required this.totalLetters,
    required this.pendingLedgers,
    required this.pendingOnboarding,
    required this.pendingUpdates,
    required this.pendingMutations,
    required this.totalUnits,
  });

  final int totalMembers;
  final double totalDuesThisMonth;
  final int totalAspirations;
  final int totalLetters;
  final int pendingLedgers;
  final int pendingOnboarding;
  final int pendingUpdates;
  final int pendingMutations;
  final int totalUnits;
}

class AdminMemberModel {
  const AdminMemberModel({
    required this.id,
    required this.name,
    this.email,
    required this.npa,
    this.role,
    this.unitName,
    this.status,
  });

  final int id;
  final String name;
  final String? email;
  final String npa;
  final String? role;
  final String? unitName;
  final String? status;

  factory AdminMemberModel.fromJson(Map<String, dynamic> json) {
    String? nullIfEmpty(String v) => v.isEmpty ? null : v;
    final unit = readMap(json, 'organization_unit').isNotEmpty
        ? readMap(json, 'organization_unit')
        : readMap(json, 'unit');
    final role = readMap(json, 'role');

    return AdminMemberModel(
      id: readInt(json, const ['id']),
      name: readString(json, const ['full_name', 'name']),
      email: nullIfEmpty(readString(json, const ['email'], fallback: '')),
      npa: readString(json, const ['npa', 'nra', 'kta_number'], fallback: '-'),
      role: nullIfEmpty(
        readString(role.isNotEmpty ? role : json, const [
          'label',
          'name',
          'role',
        ], fallback: ''),
      ),
      unitName: nullIfEmpty(
        readString(unit.isNotEmpty ? unit : json, const [
          'name',
          'unit_name',
        ], fallback: ''),
      ),
      status: nullIfEmpty(readString(json, const ['status'], fallback: '')),
    );
  }
}

class AdminMemberPageModel {
  const AdminMemberPageModel({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminMemberModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
