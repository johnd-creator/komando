// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dues_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuesPayment _$DuesPaymentFromJson(Map<String, dynamic> json) => DuesPayment(
  id: (json['id'] as num?)?.toInt(),
  memberId: (json['member_id'] as num?)?.toInt(),
  memberName: json['member_name'] as String?,
  ktaNumber: json['kta_number'] as String?,
  period: json['period'] as String,
  status: json['status'] as String,
  amount: (json['amount'] as num).toDouble(),
  paidAt: json['paid_at'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$DuesPaymentToJson(DuesPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'member_id': instance.memberId,
      'member_name': instance.memberName,
      'kta_number': instance.ktaNumber,
      'period': instance.period,
      'status': instance.status,
      'amount': instance.amount,
      'paid_at': instance.paidAt,
      'notes': instance.notes,
    };
