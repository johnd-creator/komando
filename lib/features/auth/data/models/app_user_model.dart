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
    final userJson = _readUserJson(json);
    final roleJson = _readRoleJson(userJson);
    final roleMap = roleJson is Map<String, dynamic> ? roleJson : null;
    final roleName = _readString(roleMap ?? userJson, const [
      'name',
      'role_name',
      'roleName',
      'role',
    ], fallback: roleJson is String ? roleJson : 'anggota');

    return AppUserModel(
      id: (userJson['id'] as num?)?.toInt() ?? 0,
      name: userJson['name'] as String? ?? '-',
      email: userJson['email'] as String? ?? '-',
      roleName: roleName,
      roleLabel: _readString(roleMap ?? userJson, const [
        'label',
        'role_label',
        'roleLabel',
      ], fallback: roleName),
    );
  }

  static Map<String, dynamic> _readUserJson(Map<String, dynamic> json) {
    var current = json;

    for (var i = 0; i < 4; i++) {
      final user = current['user'];
      final data = current['data'];

      if (user is Map<String, dynamic>) {
        current = user;
        continue;
      }
      if (data is Map<String, dynamic>) {
        current = data;
        continue;
      }
      break;
    }

    return current;
  }

  static Object? _readRoleJson(Map<String, dynamic> json) {
    final role = json['role'];
    if (role != null) {
      return role;
    }

    final roles = json['roles'];
    if (roles is List && roles.isNotEmpty) {
      return roles.first;
    }

    return null;
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }
}
