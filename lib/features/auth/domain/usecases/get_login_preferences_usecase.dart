import '../entities/login_preferences.dart';
import '../repositories/auth_repository.dart';

class GetLoginPreferencesUseCase {
  const GetLoginPreferencesUseCase(this._repository);

  final AuthRepository _repository;

  Future<LoginPreferences> call() {
    return _repository.getLoginPreferences();
  }
}
