import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roleName,
    required this.roleLabel,
    this.currentUnitId,
  });

  final int id;
  final String name;
  final String email;
  final String roleName;
  final String roleLabel;
  final int? currentUnitId;

  String get normalizedRoleName =>
      roleName.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  bool get hasAdminAccess => normalizedRoleName != 'anggota';

  bool get canAccessFinance {
    final role = normalizedRoleName;

    return const {
      'super_admin',
      'superadmin',
      'admin_pusat',
      'admin_unit',
      'bendahara',
      'bendahara_pusat',
      'pengurus',
      'pengurus_pusat',
    }.contains(role);
  }

  @override
  List<Object?> get props => [id, name, email, roleName, roleLabel, currentUnitId];
}
