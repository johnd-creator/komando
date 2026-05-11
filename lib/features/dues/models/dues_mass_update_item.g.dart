// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dues_mass_update_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuesMassUpdateItem _$DuesMassUpdateItemFromJson(Map<String, dynamic> json) =>
    DuesMassUpdateItem(
      memberId: (json['member_id'] as num).toInt(),
      period: json['period'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidAt: json['paid_at'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$DuesMassUpdateItemToJson(DuesMassUpdateItem instance) =>
    <String, dynamic>{
      'member_id': instance.memberId,
      'period': instance.period,
      'status': instance.status,
      'amount': instance.amount,
      'paid_at': instance.paidAt,
      'notes': instance.notes,
    };
