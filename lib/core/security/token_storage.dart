import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _rememberedEmailKey = 'remembered_email';
  static const _biometricEnabledKey = 'biometric_enabled';

  final FlutterSecureStorage _secureStorage;

  Future<String?> readAccessToken() {
    return _secureStorage.read(key: _accessTokenKey);
  }

  Future<void> saveAccessToken(String token) {
    return _secureStorage.write(key: _accessTokenKey, value: token);
  }

  Future<void> clearAccessToken() {
    return _secureStorage.delete(key: _accessTokenKey);
  }

  Future<String?> readRememberedEmail() {
    return _secureStorage.read(key: _rememberedEmailKey);
  }

  Future<void> saveRememberedEmail(String email) {
    return _secureStorage.write(key: _rememberedEmailKey, value: email);
  }

  Future<void> clearRememberedEmail() {
    return _secureStorage.delete(key: _rememberedEmailKey);
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool isEnabled) {
    return _secureStorage.write(
      key: _biometricEnabledKey,
      value: isEnabled ? 'true' : 'false',
    );
  }

  Future<void> clearBiometricEnabled() {
    return _secureStorage.delete(key: _biometricEnabledKey);
  }
}
