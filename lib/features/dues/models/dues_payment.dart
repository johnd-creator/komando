import 'package:json_annotation/json_annotation.dart';

import '../../../core/api/json_read.dart';

part 'dues_payment.g.dart';

@JsonSerializable()
class DuesPayment {
  final int? id;
  @JsonKey(name: 'member_id')
  final int? memberId;
  @JsonKey(name: 'member_name')
  final String? memberName;
  @JsonKey(name: 'kta_number')
  final String? ktaNumber;
  final String period;
  final String status;
  final double amount;
  @JsonKey(name: 'paid_at')
  final String? paidAt;
  final String? notes;

  const DuesPayment({
    this.id,
    this.memberId,
    this.memberName,
    this.ktaNumber,
    required this.period,
    required this.status,
    required this.amount,
    this.paidAt,
    this.notes,
  });

  bool get isPaid => status == 'paid';
  bool get isWaived => status == 'waived';

  String get formattedPeriod {
    try {
      final parts = period.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final monthNum = int.parse(parts[1]);
        const months = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        if (monthNum >= 1 && monthNum <= 12) {
          return '${months[monthNum - 1]} $year';
        }
      }
    } catch (_) {}
    return period;
  }

  factory DuesPayment.fromJson(Map<String, dynamic> json) {
    // Extract member info from nested 'member' object if present
    final memberObj = json['member'];
    int? memberId;
    String? memberName;
    if (memberObj is Map<String, dynamic>) {
      memberId = (memberObj['id'] as num?)?.toInt();
      memberName = memberObj['name'] as String?;
    }
    memberId ??= (json['member_id'] as num?)?.toInt();
    memberName ??= readString(json, const [
      'member_name',
      'full_name',
      'name',
    ], fallback: '');
    if (memberName.isEmpty) {
      memberName = null;
    }

    return _$DuesPaymentFromJson({
      'id': json['id'] ?? json['dues_payment_id'],
      'member_id': memberId,
      'member_name': memberName,
      'kta_number': _readNullableString(json['kta_number']),
      'period': readString(json, const ['period'], fallback: '-'),
      'status': readString(json, const [
        'status',
        'dues_status',
      ], fallback: 'unpaid'),
      'amount': readDouble(json, const ['amount']),
      'paid_at': _readNullableString(json['paid_at']),
      'notes': _readNullableString(json['notes']),
    });
  }

  Map<String, dynamic> toJson() => _$DuesPaymentToJson(this);

  static String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }
}
