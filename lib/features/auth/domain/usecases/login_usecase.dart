import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
    required String deviceName,
    bool rememberAccount = false,
    bool enableBiometric = false,
  }) {
    return _repository.login(
      email: email,
      password: password,
      deviceName: deviceName,
      rememberAccount: rememberAccount,
      enableBiometric: enableBiometric,
    );
  }
}
