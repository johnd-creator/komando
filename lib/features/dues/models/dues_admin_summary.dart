import 'package:json_annotation/json_annotation.dart';

import '../../../core/api/json_read.dart';

part 'dues_admin_summary.g.dart';

@JsonSerializable()
class DuesAdminSummary {
  final int paid;
  final int unpaid;
  final int waived;
  @JsonKey(name: 'total_amount')
  final double totalAmount;

  const DuesAdminSummary({
    required this.paid,
    required this.unpaid,
    required this.waived,
    required this.totalAmount,
  });

  factory DuesAdminSummary.fromJson(Map<String, dynamic> json) =>
      _$DuesAdminSummaryFromJson({
        'paid': readInt(json, const ['paid']),
        'unpaid': readInt(json, const ['unpaid']),
        'waived': readInt(json, const ['waived']),
        'total_amount': readDouble(json, const ['total_amount']),
      });

  Map<String, dynamic> toJson() => _$DuesAdminSummaryToJson(this);
}
