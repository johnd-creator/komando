import 'package:json_annotation/json_annotation.dart';

part 'dues_mass_update_item.g.dart';

@JsonSerializable()
class DuesMassUpdateItem {
  @JsonKey(name: 'member_id')
  final int memberId;
  final String period;
  final String status;
  final double amount;
  @JsonKey(name: 'paid_at')
  final String? paidAt;
  final String? notes;

  DuesMassUpdateItem({
    required this.memberId,
    required this.period,
    required this.status,
    required this.amount,
    this.paidAt,
    this.notes,
  });

  factory DuesMassUpdateItem.fromJson(Map<String, dynamic> json) => _$DuesMassUpdateItemFromJson(json);
  Map<String, dynamic> toJson() => _$DuesMassUpdateItemToJson(this);
}
