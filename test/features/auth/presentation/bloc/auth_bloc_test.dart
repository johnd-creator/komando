import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:komando/features/auth/domain/entities/app_user.dart';
import 'package:komando/features/auth/domain/repositories/auth_repository.dart';
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
  _FakeAuthRepository({this.restoreSessionResult, this.shouldThrow = false});

  final AppUser? loginResult;
  final AppUser? restoreSessionResult;
  final bool shouldThrow;

  @override
  Future<AppUser> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    if (shouldThrow) throw Exception('Login gagal');
    return loginResult ?? testUser;
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (shouldThrow) throw Exception('Session error');
    return restoreSessionResult;
  }

  @override
  Future<void> logout() async {}
}

void main() {
  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      final bloc = AuthBloc(
        loginUseCase: LoginUseCase(_FakeAuthRepository()),
        logoutUseCase: LogoutUseCase(_FakeAuthRepository()),
        restoreSessionUseCase: RestoreSessionUseCase(_FakeAuthRepository()),
      );
      expect(bloc.state, isA<AuthInitial>());
    });

    test('login success emits AuthAuthenticated', () {
      final repo = _FakeAuthRepository();
      final bloc = AuthBloc(
        loginUseCase: LoginUseCase(repo),
        logoutUseCase: LogoutUseCase(repo),
        restoreSessionUseCase: RestoreSessionUseCase(repo),
      );

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
      final bloc = AuthBloc(
        loginUseCase: LoginUseCase(repo),
        logoutUseCase: LogoutUseCase(repo),
        restoreSessionUseCase: RestoreSessionUseCase(repo),
      );

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
      final bloc = AuthBloc(
        loginUseCase: LoginUseCase(repo),
        logoutUseCase: LogoutUseCase(repo),
        restoreSessionUseCase: RestoreSessionUseCase(repo),
      );

      bloc.add(const AuthLogoutRequested());

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );
    });

    test('restore session with user emits AuthAuthenticated', () {
      final repo = _FakeAuthRepository(restoreSessionResult: testUser);
      final bloc = AuthBloc(
        loginUseCase: LoginUseCase(repo),
        logoutUseCase: LogoutUseCase(repo),
        restoreSessionUseCase: RestoreSessionUseCase(repo),
      );

      bloc.add(const AuthSessionRestoreRequested());

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );
    });

    test('restore session with null emits AuthUnauthenticated', () {
      final repo = _FakeAuthRepository(restoreSessionResult: null);
      final bloc = AuthBloc(
        loginUseCase: LoginUseCase(repo),
        logoutUseCase: LogoutUseCase(repo),
        restoreSessionUseCase: RestoreSessionUseCase(repo),
      );

      bloc.add(const AuthSessionRestoreRequested());

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );
    });
  });
}
