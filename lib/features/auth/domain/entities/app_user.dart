import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roleName,
    required this.roleLabel,
  });

  final int id;
  final String name;
  final String email;
  final String roleName;
  final String roleLabel;

  bool get hasAdminAccess => roleName != 'anggota';

  @override
  List<Object?> get props => [id, name, email, roleName, roleLabel];
}
