import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komando/core/api/api_client.dart';
import 'package:komando/core/security/biometric_auth_service.dart';
import 'package:komando/core/security/token_storage.dart';
import 'package:komando/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:komando/features/auth/data/models/app_user_model.dart';
import 'package:komando/features/auth/data/repositories/auth_repository_impl.dart';

const testUser = AppUserModel(
  id: 1,
  name: 'Test User',
  email: 'test@example.com',
  roleName: 'anggota',
  roleLabel: 'Anggota',
);

class _FakeTokenStorage extends TokenStorage {
  final calls = <String>[];

  String? accessToken = 'old-token';
  String? rememberedEmail;
  bool biometricEnabled = true;

  @override
  Future<String?> readAccessToken() async {
    calls.add('readAccessToken');
    return accessToken;
  }

  @override
  Future<void> saveAccessToken(String token) async {
    calls.add('saveAccessToken:$token');
    accessToken = token;
  }

  @override
  Future<void> clearAccessToken() async {
    calls.add('clearAccessToken');
    accessToken = null;
  }

  @override
  Future<String?> readRememberedEmail() async {
    calls.add('readRememberedEmail');
    return rememberedEmail;
  }

  @override
  Future<void> saveRememberedEmail(String email) async {
    calls.add('saveRememberedEmail:$email');
    rememberedEmail = email;
  }

  @override
  Future<void> clearRememberedEmail() async {
    calls.add('clearRememberedEmail');
    rememberedEmail = null;
  }

  @override
  Future<bool> isBiometricEnabled() async {
    calls.add('isBiometricEnabled');
    return biometricEnabled;
  }

  @override
  Future<void> setBiometricEnabled(bool isEnabled) async {
    calls.add('setBiometricEnabled:$isEnabled');
    biometricEnabled = isEnabled;
  }

  @override
  Future<void> clearBiometricEnabled() async {
    calls.add('clearBiometricEnabled');
    biometricEnabled = false;
  }
}

class _FakeBiometricAuthService extends BiometricAuthService {
  @override
  Future<bool> canAuthenticate() async => true;

  @override
  Future<bool> authenticate() async => true;
}

class _FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({
    required this.calls,
    this.loginToken = 'manual-token',
    this.throwOnMe = false,
  }) : super(ApiClient(dio: Dio(), tokenStorage: _FakeTokenStorage()));

  final List<String> calls;
  final String loginToken;
  final bool throwOnMe;

  @override
  Future<({String accessToken, AppUserModel user})> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    calls.add('remoteLogin');
    return (accessToken: loginToken, user: testUser);
  }

  @override
  Future<({String accessToken, AppUserModel user})> googleLogin({
    required String idToken,
    String? serverAuthCode,
  }) async {
    calls.add('remoteGoogleLogin');
    return (accessToken: 'google-token', user: testUser);
  }

  @override
  Future<AppUserModel> me() async {
    calls.add('remoteMe');
    if (throwOnMe) {
      throw Exception('Token invalid');
    }
    return testUser;
  }

  @override
  Future<void> logout() async {
    calls.add('remoteLogout');
  }
}

AuthRepositoryImpl _buildRepository({
  required _FakeTokenStorage tokenStorage,
  required _FakeAuthRemoteDataSource remoteDataSource,
}) {
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    tokenStorage: tokenStorage,
    biometricAuthService: _FakeBiometricAuthService(),
  );
}

void main() {
  group('AuthRepositoryImpl', () {
    test(
      'login clears saved session before remote login and saves valid token',
      () async {
        final tokenStorage = _FakeTokenStorage();
        final remoteCalls = <String>[];
        final repository = _buildRepository(
          tokenStorage: tokenStorage,
          remoteDataSource: _FakeAuthRemoteDataSource(calls: remoteCalls),
        );

        final user = await repository.login(
          email: ' test@example.com ',
          password: 'secret',
          deviceName: 'flutter',
        );

        expect(user, testUser);
        expect(tokenStorage.accessToken, 'manual-token');
        expect(tokenStorage.biometricEnabled, isFalse);
        expect(tokenStorage.calls, [
          'clearAccessToken',
          'clearBiometricEnabled',
          'saveAccessToken:manual-token',
          'clearRememberedEmail',
          'setBiometricEnabled:false',
        ]);
        expect(remoteCalls, ['remoteLogin']);
      },
    );

    test(
      'login throws and does not save token when server returns empty token',
      () async {
        final tokenStorage = _FakeTokenStorage();
        final remoteCalls = <String>[];
        final repository = _buildRepository(
          tokenStorage: tokenStorage,
          remoteDataSource: _FakeAuthRemoteDataSource(
            calls: remoteCalls,
            loginToken: '',
          ),
        );

        await expectLater(
          repository.login(
            email: 'test@example.com',
            password: 'secret',
            deviceName: 'flutter',
          ),
          throwsException,
        );

        expect(tokenStorage.accessToken, isNull);
        expect(tokenStorage.calls, [
          'clearAccessToken',
          'clearBiometricEnabled',
        ]);
        expect(remoteCalls, ['remoteLogin']);
      },
    );

    test(
      'google login clears saved session before remote login and saves valid token',
      () async {
        final tokenStorage = _FakeTokenStorage();
        final remoteCalls = <String>[];
        final repository = _buildRepository(
          tokenStorage: tokenStorage,
          remoteDataSource: _FakeAuthRemoteDataSource(calls: remoteCalls),
        );

        final user = await repository.loginWithGoogle(idToken: 'id-token');

        expect(user, testUser);
        expect(tokenStorage.accessToken, 'google-token');
        expect(tokenStorage.biometricEnabled, isFalse);
        expect(tokenStorage.calls, [
          'clearAccessToken',
          'clearBiometricEnabled',
          'saveAccessToken:google-token',
        ]);
        expect(remoteCalls, ['remoteGoogleLogin']);
      },
    );

    test(
      'restoreSession clears saved session and returns null when me fails',
      () async {
        final tokenStorage = _FakeTokenStorage();
        tokenStorage.biometricEnabled = false;
        final remoteCalls = <String>[];
        final repository = _buildRepository(
          tokenStorage: tokenStorage,
          remoteDataSource: _FakeAuthRemoteDataSource(
            calls: remoteCalls,
            throwOnMe: true,
          ),
        );

        final user = await repository.restoreSession();

        expect(user, isNull);
        expect(tokenStorage.accessToken, isNull);
        expect(tokenStorage.biometricEnabled, isFalse);
        expect(tokenStorage.calls, [
          'readAccessToken',
          'isBiometricEnabled',
          'clearAccessToken',
          'clearBiometricEnabled',
        ]);
        expect(remoteCalls, ['remoteMe']);
      },
    );
  });
}
