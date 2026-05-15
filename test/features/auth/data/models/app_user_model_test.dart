import 'package:flutter_test/flutter_test.dart';
import 'package:komando/features/auth/data/models/app_user_model.dart';

void main() {
  group('AppUserModel', () {
    test('parses direct user payload with role object', () {
      final user = AppUserModel.fromJson(const {
        'id': 1,
        'name': 'Super Admin',
        'email': 'admin@example.com',
        'role': {'name': 'super_admin', 'label': 'Super Admin'},
      });

      expect(user.roleName, 'super_admin');
      expect(user.roleLabel, 'Super Admin');
      expect(user.canAccessFinance, isTrue);
    });

    test('parses local /me payload wrapped in user key', () {
      final user = AppUserModel.fromJson(const {
        'user': {
          'id': 1,
          'name': 'Super Admin',
          'email': 'admin@example.com',
          'role': {'name': 'super_admin', 'label': 'Super Admin'},
        },
      });

      expect(user.roleName, 'super_admin');
      expect(user.canAccessFinance, isTrue);
    });

    test('parses JsonResource style user.data wrapper', () {
      final user = AppUserModel.fromJson(const {
        'user': {
          'data': {
            'id': 1,
            'name': 'Super Admin',
            'email': 'admin@example.com',
            'role': {'name': 'super_admin', 'label': 'Super Admin'},
          },
        },
      });

      expect(user.roleName, 'super_admin');
      expect(user.canAccessFinance, isTrue);
    });

    test('parses roles array fallback', () {
      final user = AppUserModel.fromJson(const {
        'id': 1,
        'name': 'Super Admin',
        'email': 'admin@example.com',
        'roles': [
          {'name': 'super_admin', 'label': 'Super Admin'},
        ],
      });

      expect(user.roleName, 'super_admin');
      expect(user.canAccessFinance, isTrue);
    });

    test('parses role_name and role string fallbacks', () {
      final roleNameUser = AppUserModel.fromJson(const {
        'id': 1,
        'name': 'Super Admin',
        'email': 'admin@example.com',
        'role_name': 'super_admin',
        'role_label': 'Super Admin',
      });
      final roleStringUser = AppUserModel.fromJson(const {
        'id': 2,
        'name': 'Super Admin',
        'email': 'admin2@example.com',
        'role': 'superadmin',
      });

      expect(roleNameUser.canAccessFinance, isTrue);
      expect(roleStringUser.canAccessFinance, isTrue);
    });

    test('parses member context unit fallback', () {
      final user = AppUserModel.fromJson(const {
        'id': 1,
        'name': 'Bendahara Unit',
        'email': 'bendahara@example.com',
        'role': {'name': 'bendahara', 'label': 'Bendahara'},
        'member_context_unit_id': 7,
      });

      expect(user.currentUnitId, 7);
    });
  });
}
