import '../../../../core/api/json_read.dart';

class FinanceDashboardModel {
  const FinanceDashboardModel({
    required this.summary,
    required this.recentTransactions,
    required this.userRole,
  });

  final DashboardSummary summary;
  final List<FinanceLedgerModel> recentTransactions;
  final UserRoleInfo userRole;

  factory FinanceDashboardModel.fromJson(Map<String, dynamic> json) {
    return FinanceDashboardModel(
      summary: DashboardSummary.fromJson(readMap(json, 'summary')),
      recentTransactions: readList(
        json,
        'recent_transactions',
      ).map((e) => FinanceLedgerModel.fromJson(e)).toList(),
      userRole: UserRoleInfo.fromJson(readMap(json, 'user_role')),
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.balance,
    required this.incomeThisMonth,
    required this.expenseThisMonth,
    required this.pendingCount,
  });

  final double balance;
  final double incomeThisMonth;
  final double expenseThisMonth;
  final int pendingCount;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      balance: readDouble(json, const ['balance']),
      incomeThisMonth: readDouble(json, const ['income_this_month']),
      expenseThisMonth: readDouble(json, const ['expense_this_month']),
      pendingCount: readInt(json, const ['pending_count'], fallback: 0),
    );
  }
}

class FinanceLedgerModel {
  const FinanceLedgerModel({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    this.category,
    this.unit,
    this.approvedBy,
    this.createdBy,
    this.approvedAt,
    this.attachmentPath,
    this.rejectionReason,
    this.permissions = const LedgerPermissions(),
  });

  final int id;
  final String date;
  final String type;
  final double amount;
  final String description;
  final String status;
  final LedgerCategory? category;
  final LedgerUnit? unit;
  final LedgerActor? approvedBy;
  final LedgerActor? createdBy;
  final String? approvedAt;
  final String? attachmentPath;
  final String? rejectionReason;
  final LedgerPermissions permissions;

  int? get categoryId => category?.id;
  int? get unitId => unit?.id;
  String get categoryName => category?.name ?? '';
  String get createdByName => createdBy?.name ?? '';

  factory FinanceLedgerModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    final orgUnit = json['organization_unit'] as Map<String, dynamic>?;
    final approved = json['approved_by'] as Map<String, dynamic>?;
    final created =
        json['creator'] as Map<String, dynamic>? ??
        json['created_by'] as Map<String, dynamic>?;

    return FinanceLedgerModel(
      id: readInt(json, const ['id']),
      date: readString(json, const ['date']),
      type: readString(json, const ['type'], fallback: 'income'),
      amount: readDouble(json, const ['amount']),
      description: readString(json, const ['description'], fallback: ''),
      status: readString(json, const ['status'], fallback: 'draft'),
      category: cat != null ? LedgerCategory.fromJson(cat) : null,
      unit: orgUnit != null ? LedgerUnit.fromJson(orgUnit) : null,
      approvedBy: approved != null ? LedgerActor.fromJson(approved) : null,
      createdBy: created != null ? LedgerActor.fromJson(created) : null,
      approvedAt: readString(json, const ['approved_at'], fallback: ''),
      attachmentPath: readString(json, const ['attachment_path'], fallback: ''),
      rejectionReason: readString(json, const [
        'rejected_reason',
        'rejection_reason',
      ], fallback: ''),
      permissions: LedgerPermissions.fromJson(readMap(json, 'permissions')),
    );
  }
}

class LedgerPermissions {
  const LedgerPermissions({
    this.canView = false,
    this.canUpdate = false,
    this.canDelete = false,
    this.canApprove = false,
    this.canReject = false,
  });

  final bool canView;
  final bool canUpdate;
  final bool canDelete;
  final bool canApprove;
  final bool canReject;

  factory LedgerPermissions.fromJson(Map<String, dynamic> json) {
    return LedgerPermissions(
      canView: json['view'] == true,
      canUpdate: json['update'] == true,
      canDelete: json['delete'] == true,
      canApprove: json['approve'] == true,
      canReject: json['reject'] == true,
    );
  }
}

class LedgerCategory {
  const LedgerCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory LedgerCategory.fromJson(Map<String, dynamic> json) {
    return LedgerCategory(
      id: readInt(json, const ['id']),
      name: readString(json, const ['name']),
    );
  }
}

class LedgerUnit {
  const LedgerUnit({required this.id, required this.name, required this.code});

  final int id;
  final String name;
  final String code;

  factory LedgerUnit.fromJson(Map<String, dynamic> json) {
    return LedgerUnit(
      id: readInt(json, const ['id']),
      name: readString(json, const ['name']),
      code: readString(json, const ['code'], fallback: ''),
    );
  }
}

class LedgerActor {
  const LedgerActor({required this.id, required this.name});

  final int id;
  final String name;

  factory LedgerActor.fromJson(Map<String, dynamic> json) {
    return LedgerActor(
      id: readInt(json, const ['id']),
      name: readString(json, const ['name']),
    );
  }
}

class FinanceLedgerPageModel {
  const FinanceLedgerPageModel({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<FinanceLedgerModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory FinanceLedgerPageModel.fromJson(Map<String, dynamic> json) {
    final meta = readMap(json, 'meta');

    return FinanceLedgerPageModel(
      items:
          (readList(json, 'ledgers').isNotEmpty
                  ? readList(json, 'ledgers')
                  : readList(json, 'data'))
              .map((e) => FinanceLedgerModel.fromJson(e))
              .toList(),
      currentPage: readInt(meta, const ['current_page'], fallback: 1),
      lastPage: readInt(meta, const ['last_page'], fallback: 1),
      total: readInt(meta, const ['total']),
    );
  }
}

class FinanceUnitModel {
  const FinanceUnitModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isPusat,
  });

  final int id;
  final String name;
  final String code;
  final bool isPusat;

  factory FinanceUnitModel.fromJson(Map<String, dynamic> json) {
    return FinanceUnitModel(
      id: readInt(json, const ['id']),
      name: readString(json, const ['name']),
      code: readString(json, const ['code'], fallback: ''),
      isPusat: json['is_pusat'] == true,
    );
  }
}

class FinanceUnitsResponse {
  const FinanceUnitsResponse({
    required this.units,
    required this.accessibleCount,
    required this.role,
  });

  final List<FinanceUnitModel> units;
  final int accessibleCount;
  final String role;

  String get normalizedRole =>
      role.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  bool get canSelectUnitForWrite =>
      const {'super_admin', 'superadmin'}.contains(normalizedRole);

  factory FinanceUnitsResponse.fromJson(Map<String, dynamic> json) {
    return FinanceUnitsResponse(
      units: readList(
        json,
        'units',
      ).map((e) => FinanceUnitModel.fromJson(e)).toList(),
      accessibleCount: readInt(json, const ['accessible_count']),
      role: readString(json, const ['role'], fallback: 'anggota'),
    );
  }
}

class UserRoleInfo {
  const UserRoleInfo({
    required this.role,
    this.unitId,
    required this.canViewGlobal,
  });

  final String role;
  final int? unitId;
  final bool canViewGlobal;

  String get normalizedRole =>
      role.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  bool get canCreateLedger {
    return const {
      'super_admin',
      'superadmin',
      'admin_pusat',
      'bendahara',
      'bendahara_pusat',
    }.contains(normalizedRole);
  }

  factory UserRoleInfo.fromJson(Map<String, dynamic> json) {
    return UserRoleInfo(
      role: readString(json, const ['role'], fallback: 'anggota'),
      unitId: readInt(json, const ['unit_id'], fallback: 0),
      canViewGlobal: json['can_view_global'] == true,
    );
  }
}

class LedgerCategoryModel {
  const LedgerCategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.isRecurring = false,
    this.defaultAmount,
  });

  final int id;
  final String name;
  final String type;
  final bool isRecurring;
  final double? defaultAmount;

  factory LedgerCategoryModel.fromJson(Map<String, dynamic> json) {
    return LedgerCategoryModel(
      id: readInt(json, const ['id']),
      name: readString(json, const ['name']),
      type: readString(json, const ['type'], fallback: 'income'),
      isRecurring: json['is_recurring'] == true,
      defaultAmount: json.containsKey('default_amount')
          ? readDouble(json, const ['default_amount'])
          : null,
    );
  }
}
