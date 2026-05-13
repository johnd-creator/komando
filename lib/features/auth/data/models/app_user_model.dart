import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.roleName,
    required super.roleLabel,
    super.currentUnitId,
    super.avatar,
    super.photoUrl,
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

    final avatar = _readNullableString(userJson, const ['avatar']);
    final memberJson = userJson['member'];
    final memberPhotoUrl = memberJson is Map<String, dynamic>
        ? _readNullableString(memberJson, const ['photo_url'])
        : null;

    // Convert relative URLs to absolute URLs
    final absoluteAvatar = avatar != null
        ? ApiConstants.getAbsolutePhotoUrl(avatar)
        : null;
    final absoluteMemberPhotoUrl = memberPhotoUrl != null
        ? ApiConstants.getAbsolutePhotoUrl(memberPhotoUrl)
        : null;

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
      currentUnitId: _readInt(userJson, const [
        'current_unit_id',
        'currentUnitId',
        'member_context_unit_id',
        'memberContextUnitId',
      ]),
      avatar: absoluteAvatar,
      photoUrl: absoluteMemberPhotoUrl ?? absoluteAvatar,
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

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
    }
    return null;
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
