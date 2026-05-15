
import '../../../../core/cache/app_cache.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/security/biometric_auth_service.dart';
import '../../../../core/security/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/login_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
    required BiometricAuthService biometricAuthService,
    AppCache? appCache,
  }) : _remoteDataSource = remoteDataSource,
       _tokenStorage = tokenStorage,
       _biometricAuthService = biometricAuthService,
       _appCache = appCache ?? AppCache();

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;
  final BiometricAuthService _biometricAuthService;
  final AppCache _appCache;

  @override
  Future<AppUser> login({
    required String email,
    required String password,
    required String deviceName,
    bool rememberAccount = false,
    bool enableBiometric = false,
  }) async {
    final normalizedEmail = email.trim();

    // Clear any existing session (token, biometric flag, cache) BEFORE
    // sending the login request. This prevents a stale Google SSO token
    // from being forwarded to the login endpoint by the Dio interceptor.
    await _clearSavedSession();
    AppLogger.i('Session cleared, sending login request', tag: 'AuthRepo');

    final result = await _remoteDataSource.login(
      email: normalizedEmail,
      password: password,
      deviceName: deviceName,
    );
    if (result.accessToken.isEmpty) {
      throw Exception('Access token kosong dari server.');
    }

    await _tokenStorage.saveAccessToken(result.accessToken);
    AppLogger.i('Login successful, token saved', tag: 'AuthRepo');

    if (rememberAccount || enableBiometric) {
      await _tokenStorage.saveRememberedEmail(normalizedEmail);
    } else {
      await _tokenStorage.clearRememberedEmail();
    }
    await _tokenStorage.setBiometricEnabled(enableBiometric);
    return result.user;
  }

  @override
  Future<LoginPreferences> getLoginPreferences() async {
    final token = await _tokenStorage.readAccessToken();
    final biometricEnabled = await _tokenStorage.isBiometricEnabled();
    final biometricAvailable = await _biometricAuthService.canAuthenticate();

    return LoginPreferences(
      rememberedEmail: await _tokenStorage.readRememberedEmail(),
      biometricEnabled: biometricEnabled,
      hasSavedSession: token != null && token.isNotEmpty,
      biometricAvailable: biometricAvailable,
    );
  }

  @override
  Future<AppUser> loginWithBiometric() async {
    final token = await _tokenStorage.readAccessToken();
    final biometricEnabled = await _tokenStorage.isBiometricEnabled();
    if (token == null || token.isEmpty || !biometricEnabled) {
      throw Exception('Biometrik belum aktif untuk akun ini.');
    }

    final authenticated = await _biometricAuthService.authenticate();
    if (!authenticated) {
      throw Exception('Autentikasi biometrik dibatalkan.');
    }

    return _remoteDataSource.me();
  }

  @override
  Future<AppUser> loginWithGoogle({
    required String idToken,
    String? serverAuthCode,
  }) async {
    // Same as manual login: clear session first so no stale token is sent.
    await _clearSavedSession();
    AppLogger.i(
      'Session cleared, sending Google login request',
      tag: 'AuthRepo',
    );

    final result = await _remoteDataSource.googleLogin(
      idToken: idToken,
      serverAuthCode: serverAuthCode,
    );
    if (result.accessToken.isEmpty) {
      throw Exception('Access token kosong dari server.');
    }

    await _tokenStorage.saveAccessToken(result.accessToken);
    AppLogger.i('Google login successful, token saved', tag: 'AuthRepo');
    return result.user;
  }

  @override
  Future<AppUser?> restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final requiresBiometric = await _tokenStorage.isBiometricEnabled();
    if (requiresBiometric) {
      return null;
    }

    try {
      return await _remoteDataSource.me();
    } catch (_) {
      await _clearSavedSession();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await _tokenStorage.clearAccessToken();
      await _tokenStorage.clearBiometricEnabled();
      await _appCache.clearUserScopedCache();
    }
  }

  Future<void> _clearSavedSession() async {
    await _tokenStorage.clearAccessToken();
    await _tokenStorage.clearBiometricEnabled();
    await _appCache.clearUserScopedCache();
  }
}
