import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';

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
}
