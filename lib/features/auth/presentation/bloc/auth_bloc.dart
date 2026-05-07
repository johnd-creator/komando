import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_error_handler.dart';
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
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _restoreSessionUseCase = restoreSessionUseCase,
       super(const AuthInitial()) {
    on<AuthSessionRestoreRequested>(_onSessionRestoreRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final RestoreSessionUseCase _restoreSessionUseCase;

  Future<void> _onSessionRestoreRequested(
    AuthSessionRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _restoreSessionUseCase();
      if (user == null) {
        emit(const AuthUnauthenticated());
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
      );
      emit(AuthAuthenticated(user));
    } catch (error) {
      emit(AuthFailure(ApiErrorHandler.getMessage(error)));
      emit(const AuthUnauthenticated());
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
}
