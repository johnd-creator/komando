import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> login({
    required String email,
    required String password,
    required String deviceName,
  });

  Future<AppUser?> restoreSession();

  Future<void> logout();
}
