import '../../../../core/api/json_read.dart';

class MemberProfileModel {
  const MemberProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.unit,
    required this.status,
    required this.memberNumber,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String unit;
  final String status;
  final String memberNumber;

  factory MemberProfileModel.fromJson(Map<String, dynamic> json) {
    final data = readMap(json, 'data').isNotEmpty
        ? readMap(json, 'data')
        : json;
    final member = readMap(data, 'member').isNotEmpty
        ? readMap(data, 'member')
        : data;
    final user = readMap(data, 'user');
    final unit = readMap(member, 'unit').isNotEmpty
        ? readMap(member, 'unit')
        : readMap(member, 'current_unit');

    return MemberProfileModel(
      name: readString(member, const [
        'name',
        'full_name',
      ], fallback: readString(user, const ['name'], fallback: 'Anggota')),
      email: readString(user.isNotEmpty ? user : member, const ['email']),
      phone: readString(member, const [
        'phone',
        'phone_number',
        'mobile',
      ], fallback: '-'),
      address: readString(member, const ['address'], fallback: '-'),
      unit: readString(unit.isNotEmpty ? unit : member, const [
        'name',
        'unit_name',
      ], fallback: '-'),
      status: readString(member, const [
        'status',
        'membership_status',
      ], fallback: '-'),
      memberNumber: readString(member, const [
        'nomor_anggota',
        'member_number',
        'kta_number',
      ], fallback: '-'),
    );
  }
}
