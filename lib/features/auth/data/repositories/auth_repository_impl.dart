import '../../../../core/security/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
  }) : _remoteDataSource = remoteDataSource,
       _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<AppUser> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final result = await _remoteDataSource.login(
      email: email,
      password: password,
      deviceName: deviceName,
    );
    await _tokenStorage.saveAccessToken(result.accessToken);
    return result.user;
  }

  @override
  Future<AppUser?> restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    return _remoteDataSource.me();
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await _tokenStorage.clearAccessToken();
    }
  }
}
