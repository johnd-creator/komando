import 'package:json_annotation/json_annotation.dart';

part 'dues_summary.g.dart';

@JsonSerializable()
class DuesSummary {
  @JsonKey(name: 'current_period')
  final String currentPeriod;
  @JsonKey(name: 'current_status')
  final String currentStatus;
  @JsonKey(name: 'unpaid_count')
  final int unpaidCount;
  @JsonKey(name: 'unpaid_periods')
  final List<String> unpaidPeriods;

  DuesSummary({
    required this.currentPeriod,
    required this.currentStatus,
    required this.unpaidCount,
    required this.unpaidPeriods,
  });

  factory DuesSummary.fromJson(Map<String, dynamic> json) => _$DuesSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DuesSummaryToJson(this);
}
