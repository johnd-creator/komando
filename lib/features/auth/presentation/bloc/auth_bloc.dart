import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
import '../../domain/usecases/biometric_login_usecase.dart';
import '../../domain/usecases/get_login_preferences_usecase.dart';
import '../../domain/usecases/google_login_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
    required GetLoginPreferencesUseCase getLoginPreferencesUseCase,
    required BiometricLoginUseCase biometricLoginUseCase,
    required GoogleLoginUseCase googleLoginUseCase,
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _restoreSessionUseCase = restoreSessionUseCase,
       _getLoginPreferencesUseCase = getLoginPreferencesUseCase,
       _biometricLoginUseCase = biometricLoginUseCase,
       _googleLoginUseCase = googleLoginUseCase,
       super(const AuthInitial()) {
    on<AuthSessionRestoreRequested>(_onSessionRestoreRequested);
    on<AuthLoginOptionsRequested>(_onLoginOptionsRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthBiometricLoginRequested>(_onBiometricLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
  }

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final RestoreSessionUseCase _restoreSessionUseCase;
  final GetLoginPreferencesUseCase _getLoginPreferencesUseCase;
  final BiometricLoginUseCase _biometricLoginUseCase;
  final GoogleLoginUseCase _googleLoginUseCase;

  Future<void> _onSessionRestoreRequested(
    AuthSessionRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _restoreSessionUseCase();
      if (user == null) {
        final preferences = await _getLoginPreferencesUseCase();
        emit(AuthLoginOptionsLoaded(preferences));
        return;
      }
      emit(AuthAuthenticated(user));
    } catch (error) {
      emit(AuthFailure(ApiErrorHandler.getMessage(error)));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _loginUseCase(
        email: event.email.trim(),
        password: event.password,
        deviceName: 'flutter',
        rememberAccount: event.rememberAccount,
        enableBiometric: event.enableBiometric,
      );
      emit(AuthAuthenticated(user));
    } catch (error) {
      emit(AuthFailure(ApiErrorHandler.getMessage(error)));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginOptionsRequested(
    AuthLoginOptionsRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final preferences = await _getLoginPreferencesUseCase();
      emit(AuthLoginOptionsLoaded(preferences));
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onBiometricLoginRequested(
    AuthBiometricLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _biometricLoginUseCase();
      emit(AuthAuthenticated(user));
    } catch (error) {
      emit(AuthFailure(ApiErrorHandler.getMessage(error)));
      final preferences = await _getLoginPreferencesUseCase();
      emit(AuthLoginOptionsLoaded(preferences));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _logoutUseCase();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _googleLoginUseCase(
        idToken: event.idToken,
        serverAuthCode: event.serverAuthCode,
      );
      emit(AuthAuthenticated(user));
    } catch (error) {
      emit(AuthFailure(ApiErrorHandler.getMessage(error)));
      emit(const AuthUnauthenticated());
    }
  }
}
