import 'package:flutter_test/flutter_test.dart';
import 'package:komando/features/auth/domain/entities/app_user.dart';

void main() {
  group('AppUser', () {
    test('allows finance access for superadmin role aliases', () {
      const roles = ['super_admin', 'superadmin', 'super-admin', 'Super Admin'];

      for (final role in roles) {
        final user = AppUser(
          id: 1,
          name: 'Admin',
          email: 'admin@example.com',
          roleName: role,
          roleLabel: 'Super Admin',
        );

        expect(user.canAccessFinance, isTrue, reason: role);
        expect(user.hasAdminAccess, isTrue, reason: role);
      }
    });

    test('does not allow finance access for regular member', () {
      const user = AppUser(
        id: 2,
        name: 'Member',
        email: 'member@example.com',
        roleName: 'anggota',
        roleLabel: 'Anggota',
      );

      expect(user.canAccessFinance, isFalse);
      expect(user.hasAdminAccess, isFalse);
    });
  });
}
