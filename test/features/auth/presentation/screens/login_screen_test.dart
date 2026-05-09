import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:komando/features/auth/presentation/screens/login_screen.dart';

const testUser = AppUser(
  id: 1,
  name: 'Test User',
  email: 'test@example.com',
  roleName: 'anggota',
  roleLabel: 'Anggota',
);

class _FakeAuthRepository implements AuthRepository {
  int googleLoginCallCount = 0;

  @override
  Future<AppUser> login({
    required String email,
    required String password,
    required String deviceName,
    bool rememberAccount = false,
    bool enableBiometric = false,
  }) async {
    return testUser;
  }

  @override
  Future<LoginPreferences> getLoginPreferences() async {
    return const LoginPreferences();
  }

  @override
  Future<AppUser> loginWithBiometric() async {
    return testUser;
  }

  @override
  Future<AppUser> loginWithGoogle({
    required String idToken,
    String? serverAuthCode,
  }) async {
    googleLoginCallCount += 1;
    return testUser;
  }

  @override
  Future<AppUser?> restoreSession() async {
    return null;
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
  testWidgets(
    'Google button shows temporary message without dispatching login',
    (tester) async {
      final repo = _FakeAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => _buildBloc(repo),
            child: const LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Masuk dengan Google'));
      await tester.pump();

      expect(
        find.text(
          'Login Google sedang disiapkan. Silakan gunakan login manual.',
        ),
        findsOneWidget,
      );
      expect(repo.googleLoginCallCount, 0);
    },
  );
}
