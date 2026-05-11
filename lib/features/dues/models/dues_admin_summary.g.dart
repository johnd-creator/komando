// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dues_admin_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuesAdminSummary _$DuesAdminSummaryFromJson(Map<String, dynamic> json) =>
    DuesAdminSummary(
      paid: (json['paid'] as num).toInt(),
      unpaid: (json['unpaid'] as num).toInt(),
      waived: (json['waived'] as num).toInt(),
      totalAmount: (json['total_amount'] as num).toDouble(),
    );

Map<String, dynamic> _$DuesAdminSummaryToJson(DuesAdminSummary instance) =>
    <String, dynamic>{
      'paid': instance.paid,
      'unpaid': instance.unpaid,
      'waived': instance.waived,
      'total_amount': instance.totalAmount,
    };
