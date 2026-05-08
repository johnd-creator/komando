import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GoogleLoginUseCase {
  const GoogleLoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String idToken,
    String? serverAuthCode,
  }) {
    return _repository.loginWithGoogle(
      idToken: idToken,
      serverAuthCode: serverAuthCode,
    );
  }
}
