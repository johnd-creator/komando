import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppCache {
  AppCache({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const newsFirstPageKey = 'cache.news.first_page';
  static const profileKey = 'cache.profile';
  static const ktaCardKey = 'cache.kta.card';
  static const ktaQrKey = 'cache.kta.qr';

  static const userScopedKeys = [
    newsFirstPageKey,
    profileKey,
    ktaCardKey,
    ktaQrKey,
  ];

  final FlutterSecureStorage _storage;

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) {
    return _storage.write(key: key, value: jsonEncode(value));
  }

  Future<Uint8List?> readBytes(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return null;
    return base64Decode(raw);
  }

  Future<void> writeBytes(String key, Uint8List value) {
    return _storage.write(key: key, value: base64Encode(value));
  }

  Future<void> clearUserScopedCache() async {
    for (final key in userScopedKeys) {
      try {
        await _storage.delete(key: key);
      } catch (_) {
        // Cache cleanup must not block auth/session changes.
      }
    }
  }
}
