import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSessionRestoreRequested extends AuthEvent {
  const AuthSessionRestoreRequested();
}

class AuthLoginOptionsRequested extends AuthEvent {
  const AuthLoginOptionsRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.rememberAccount = false,
    this.enableBiometric = false,
  });

  final String email;
  final String password;
  final bool rememberAccount;
  final bool enableBiometric;

  @override
  List<Object?> get props => [
    email,
    password,
    rememberAccount,
    enableBiometric,
  ];
}

class AuthBiometricLoginRequested extends AuthEvent {
  const AuthBiometricLoginRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested({
    required this.idToken,
    this.serverAuthCode,
  });

  final String idToken;
  final String? serverAuthCode;

  @override
  List<Object?> get props => [idToken, serverAuthCode];
}
