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
    this.preferences = const LoginPreferences(),
    this.shouldThrowLogin = false,
    this.shouldThrowRestoreSession = false,
  });

  final AppUser? restoreSessionResult;
  final LoginPreferences preferences;
  final bool shouldThrowLogin;
  final bool shouldThrowRestoreSession;

  @override
  Future<AppUser> login({
    required String email,
    required String password,
    required String deviceName,
    bool rememberAccount = false,
    bool enableBiometric = false,
  }) async {
    if (shouldThrowLogin) throw Exception('Login gagal');
    return testUser;
  }

  @override
  Future<LoginPreferences> getLoginPreferences() async => preferences;

  @override
  Future<AppUser> loginWithBiometric() async => testUser;

  @override
  Future<AppUser> loginWithGoogle({
    required String idToken,
    String? serverAuthCode,
  }) async {
    return testUser;
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (shouldThrowRestoreSession) throw Exception('Session error');
    return restoreSessionResult;
  }

  @override
  Future<void> logout() async {}
}

AuthBloc _buildBloc(_FakeAuthRepository repo) {
  return AuthBloc(
    loginUseCase: LoginUseCase(repo),
    logoutUseCase: LogoutUseCase(repo),
    restoreSessionUseCase: RestoreSessionUseCase(repo),
    getLoginPreferencesUseCase: GetLoginPreferencesUseCase(repo),
    biometricLoginUseCase: BiometricLoginUseCase(repo),
    googleLoginUseCase: GoogleLoginUseCase(repo),
  );
}

void main() {
  group('AuthBloc', () {
    test('initial state is AuthInitial', () async {
      final bloc = _buildBloc(_FakeAuthRepository());
      addTearDown(bloc.close);

      expect(bloc.state, isA<AuthInitial>());
    });

    test('login success emits AuthAuthenticated', () async {
      final bloc = _buildBloc(_FakeAuthRepository());
      addTearDown(bloc.close);

      bloc.add(
        const AuthLoginRequested(email: 'test@example.com', password: 'pass'),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );
    });

    test('login failure emits AuthFailure then AuthUnauthenticated', () async {
      final bloc = _buildBloc(_FakeAuthRepository(shouldThrowLogin: true));
      addTearDown(bloc.close);

      bloc.add(
        const AuthLoginRequested(email: 'test@example.com', password: 'wrong'),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthFailure>(),
          isA<AuthUnauthenticated>(),
        ]),
      );
    });

    test('logout emits AuthUnauthenticated', () async {
      final bloc = _buildBloc(_FakeAuthRepository());
      addTearDown(bloc.close);

      bloc.add(const AuthLogoutRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );
    });

    test('restore session with user emits AuthAuthenticated', () async {
      final bloc = _buildBloc(
        _FakeAuthRepository(restoreSessionResult: testUser),
      );
      addTearDown(bloc.close);

      bloc.add(const AuthSessionRestoreRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );
    });

    test('restore session without user emits login options', () async {
      final bloc = _buildBloc(
        _FakeAuthRepository(
          preferences: const LoginPreferences(
            rememberedEmail: 'test@example.com',
          ),
        ),
      );
      addTearDown(bloc.close);

      bloc.add(const AuthSessionRestoreRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthLoginOptionsLoaded>()]),
      );
    });

    test(
      'restore session failure emits AuthFailure then AuthUnauthenticated',
      () async {
        final bloc = _buildBloc(
          _FakeAuthRepository(shouldThrowRestoreSession: true),
        );
        addTearDown(bloc.close);

        bloc.add(const AuthSessionRestoreRequested());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AuthLoading>(),
            isA<AuthFailure>(),
            isA<AuthUnauthenticated>(),
          ]),
        );
      },
    );

    test('google login success emits AuthAuthenticated', () async {
      final bloc = _buildBloc(_FakeAuthRepository());
      addTearDown(bloc.close);

      bloc.add(const AuthGoogleLoginRequested(idToken: 'google-token'));

      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );
    });
  });
}
