import 'package:equatable/equatable.dart';

class LoginPreferences extends Equatable {
  const LoginPreferences({
    this.rememberedEmail,
    this.biometricEnabled = false,
    this.hasSavedSession = false,
    this.biometricAvailable = false,
  });

  final String? rememberedEmail;
  final bool biometricEnabled;
  final bool hasSavedSession;
  final bool biometricAvailable;

  bool get canUseBiometric =>
      biometricEnabled && hasSavedSession && biometricAvailable;

  @override
  List<Object?> get props => [
    rememberedEmail,
    biometricEnabled,
    hasSavedSession,
    biometricAvailable,
  ];
}
