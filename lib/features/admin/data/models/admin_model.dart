import '../../../../core/api/json_read.dart';

class AdminDashboardModel {
  const AdminDashboardModel({
    required this.totalMembers,
    required this.balance,
    required this.totalAspirations,
    required this.totalInboxLetters,
    required this.pendingLedgers,
    required this.pendingOnboarding,
    required this.pendingUpdates,
    required this.pendingMutations,
    required this.totalUnits,
  });

  final int totalMembers;
  final double balance;
  final int totalAspirations;
  final int totalInboxLetters;
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
    this.phone,
    this.position,
    this.joinedAt,
  });

  final int id;
  final String name;
  final String? email;
  final String npa;
  final String? role;
  final String? unitName;
  final String? status;
  final String? phone;
  final String? position;
  final String? joinedAt;

  factory AdminMemberModel.fromJson(Map<String, dynamic> json) {
    String? nullIfEmpty(String v) => v.isEmpty ? null : v;
    final unit = readMap(json, 'organization_unit').isNotEmpty
        ? readMap(json, 'organization_unit')
        : readMap(json, 'unit');
    final role = readMap(json, 'role');
    final position = readMap(json, 'position').isNotEmpty
        ? readMap(json, 'position')
        : readMap(json, 'union_position');

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
      phone: nullIfEmpty(
        readString(json, const [
          'phone',
          'phone_number',
          'mobile',
          'whatsapp',
        ], fallback: ''),
      ),
      position: nullIfEmpty(
        readString(position.isNotEmpty ? position : json, const [
          'name',
          'position',
          'position_name',
        ], fallback: ''),
      ),
      joinedAt: nullIfEmpty(
        readString(json, const [
          'joined_at',
          'join_date',
          'registered_at',
          'created_at',
        ], fallback: ''),
      ),
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
