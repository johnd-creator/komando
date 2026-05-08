import 'package:flutter_test/flutter_test.dart';
import 'package:komando/features/auth/domain/entities/app_user.dart';
import 'package:komando/features/auth/domain/entities/login_preferences.dart';
import 'package:komando/features/auth/domain/repositories/auth_repository.dart';
import 'package:komando/features/auth/domain/usecases/biometric_login_usecase.dart';
import 'package:komando/features/auth/domain/usecases/get_login_preferences_usecase.dart';
import 'package:komando/features/auth/domain/usecases/google_login_usecase.dart';
import 'package:komando/features/auth/domain/usecases/login_usecase.dart';
import 'package:komando/features/auth/domain/usecases/logout_usecase.dart';
import 'package:komando/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:komando/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:komando/features/auth/presentation/bloc/auth_event.dart';
import 'package:komando/features/auth/presentation/bloc/auth_state.dart';

const testUser = AppUser(
  id: 1,
  name: 'Test User',
  email: 'test@example.com',
  roleName: 'anggota',
  roleLabel: 'Anggota',
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.restoreSessionResult,
    this.shouldThrow = false,
    this.preferences = const LoginPreferences(),
  });

  final AppUser? restoreSessionResult;
  final bool shouldThrow;
  final LoginPreferences preferences;

  @override
  Future<LoginPreferences> getLoginPreferences() async => preferences;

  @override
  Future<AppUser> login({
    required String email,
    required String password,
    required String deviceName,
    bool rememberAccount = false,
    bool enableBiometric = false,
  }) async {
    if (shouldThrow) throw Exception('Login gagal');
    return testUser;
  }

  @override
  Future<AppUser> loginWithBiometric() async {
    if (shouldThrow) throw Exception('Biometric gagal');
    return testUser;
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (shouldThrow) throw Exception('Session error');
    return restoreSessionResult;
  }

  @override
  Future<AppUser> loginWithGoogle({
    required String idToken,
    String? serverAuthCode,
  }) async {
    if (shouldThrow) throw Exception('Google login gagal');
    return testUser;
  }

  @override
  Future<void> logout() async {}
}

AuthBloc _buildBloc(AuthRepository repository) {
  return AuthBloc(
    loginUseCase: LoginUseCase(repository),
    logoutUseCase: LogoutUseCase(repository),
    restoreSessionUseCase: RestoreSessionUseCase(repository),
    getLoginPreferencesUseCase: GetLoginPreferencesUseCase(repository),
    biometricLoginUseCase: BiometricLoginUseCase(repository),
    googleLoginUseCase: GoogleLoginUseCase(repository),
  );
}

void main() {
  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      final bloc = _buildBloc(_FakeAuthRepository());
      expect(bloc.state, isA<AuthInitial>());
    });

    test('login success emits AuthAuthenticated', () {
      final repo = _FakeAuthRepository();
      final bloc = _buildBloc(repo);

      bloc.add(
        const AuthLoginRequested(email: 'test@example.com', password: 'pass'),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );
    });

    test('login failure emits AuthFailure then AuthUnauthenticated', () {
      final repo = _FakeAuthRepository(shouldThrow: true);
      final bloc = _buildBloc(repo);

      bloc.add(
        const AuthLoginRequested(email: 'test@example.com', password: 'wrong'),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthFailure>(),
          isA<AuthUnauthenticated>(),
        ]),
      );
    });

    test('logout emits AuthUnauthenticated', () {
      final repo = _FakeAuthRepository();
      final bloc = _buildBloc(repo);

      bloc.add(const AuthLogoutRequested());

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );
    });

    test('restore session with user emits AuthAuthenticated', () {
      final repo = _FakeAuthRepository(restoreSessionResult: testUser);
      final bloc = _buildBloc(repo);

      bloc.add(const AuthSessionRestoreRequested());

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );
    });

    test('restore session with null emits login options', () {
      final repo = _FakeAuthRepository(restoreSessionResult: null);
      final bloc = _buildBloc(repo);

      bloc.add(const AuthSessionRestoreRequested());

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthLoginOptionsLoaded>()]),
      );
    });

    test('biometric login success emits AuthAuthenticated', () {
      final repo = _FakeAuthRepository(
        preferences: const LoginPreferences(
          biometricEnabled: true,
          biometricAvailable: true,
          hasSavedSession: true,
        ),
      );
      final bloc = _buildBloc(repo);

      bloc.add(const AuthBiometricLoginRequested());

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );
    });
  });
}
