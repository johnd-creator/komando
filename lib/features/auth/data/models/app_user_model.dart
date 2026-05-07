import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.roleName,
    required super.roleLabel,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>?;

    return AppUserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '-',
      email: json['email'] as String? ?? '-',
      roleName: role?['name'] as String? ?? 'anggota',
      roleLabel: role?['label'] as String? ?? 'Anggota',
    );
  }
}
