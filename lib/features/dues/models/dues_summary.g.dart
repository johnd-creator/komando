// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dues_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuesSummary _$DuesSummaryFromJson(Map<String, dynamic> json) => DuesSummary(
      currentPeriod: json['current_period'] as String,
      currentStatus: json['current_status'] as String,
      unpaidCount: (json['unpaid_count'] as num).toInt(),
      unpaidPeriods: (json['unpaid_periods'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$DuesSummaryToJson(DuesSummary instance) =>
    <String, dynamic>{
      'current_period': instance.currentPeriod,
      'current_status': instance.currentStatus,
      'unpaid_count': instance.unpaidCount,
      'unpaid_periods': instance.unpaidPeriods,
    };
