import '../../../../core/api/json_read.dart';

class DuesResponse {
  const DuesResponse({
    required this.hasMember,
    required this.items,
    required this.summary,
  });

  final bool hasMember;
  final List<DueModel> items;
  final DuesSummary summary;

  factory DuesResponse.fromJson(Map<String, dynamic> json) {
    final items =
        (readList(json, 'payments').isNotEmpty
                ? readList(json, 'payments')
                : readList(json, 'data'))
            .map((e) => DueModel.fromJson(e))
            .toList();

    return DuesResponse(
      hasMember: json['has_member'] != false,
      items: items,
      summary: DuesSummary.fromJson(readMap(json, 'summary'), items),
    );
  }
}

class DueModel {
  const DueModel({
    required this.id,
    required this.period,
    required this.status,
    required this.amount,
    this.paidAt,
    this.notes,
  });

  final int id;
  final String period;
  final String status;
  final double amount;
  final String? paidAt;
  final String? notes;

  factory DueModel.fromJson(Map<String, dynamic> json) {
    return DueModel(
      id: readInt(json, const ['id']),
      period: readString(json, const ['period']),
      status: readString(json, const ['status'], fallback: 'unpaid'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paidAt: readString(json, const ['paid_at'], fallback: ''),
      notes: readString(json, const ['notes'], fallback: ''),
    );
  }
}

class DuesSummary {
  const DuesSummary({
    required this.totalMonths,
    required this.paidCount,
    required this.unpaidCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.currentPeriod,
    required this.currentStatus,
  });

  final int totalMonths;
  final int paidCount;
  final int unpaidCount;
  final double totalAmount;
  final double paidAmount;
  final String currentPeriod;
  final String currentStatus;

  factory DuesSummary.fromJson(
    Map<String, dynamic> json,
    List<DueModel> items,
  ) {
    final paidItems = items
        .where((item) => item.status == 'paid' || item.status == 'lunas')
        .toList();
    final totalAmount = items.fold<double>(0, (sum, item) => sum + item.amount);
    final paidAmount = paidItems.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return DuesSummary(
      totalMonths: readInt(json, const [
        'total_months',
      ], fallback: items.length),
      paidCount: readInt(json, const [
        'paid_count',
      ], fallback: paidItems.length),
      unpaidCount: readInt(json, const [
        'unpaid_count',
      ], fallback: items.length - paidItems.length),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? totalAmount,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? paidAmount,
      currentPeriod: readString(json, const ['current_period'], fallback: ''),
      currentStatus: readString(json, const [
        'current_status',
      ], fallback: items.isNotEmpty ? items.first.status : 'unpaid'),
    );
  }
}
