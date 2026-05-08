import '../entities/app_user.dart';
import '../entities/login_preferences.dart';

abstract class AuthRepository {
  Future<AppUser> login({
    required String email,
    required String password,
    required String deviceName,
    bool rememberAccount = false,
    bool enableBiometric = false,
  });

  Future<LoginPreferences> getLoginPreferences();

  Future<AppUser> loginWithBiometric();

  Future<AppUser> loginWithGoogle({
    required String idToken,
    String? serverAuthCode,
  });

  Future<AppUser?> restoreSession();

  Future<void> logout();
}
