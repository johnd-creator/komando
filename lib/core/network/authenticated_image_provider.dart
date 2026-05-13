import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../security/token_storage.dart';

/// Custom image provider that includes authentication headers
class AuthenticatedImageProvider
    extends ImageProvider<AuthenticatedImageProvider> {
  const AuthenticatedImageProvider({
    required this.url,
    required this.tokenStorage,
    this.scale = 1.0,
  });

  final String url;
  final TokenStorage tokenStorage;
  final double scale;

  @override
  Future<AuthenticatedImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<AuthenticatedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    AuthenticatedImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<AuthenticatedImageProvider>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    AuthenticatedImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    try {
      debugPrint('[AuthenticatedImageProvider] Loading image: ${key.url}');

      final token = await tokenStorage.readAccessToken();
      final headers = <String, String>{'Accept': 'image/*'};

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('[AuthenticatedImageProvider] Using auth token');
      }

      final response = await http.get(Uri.parse(key.url), headers: headers);

      if (response.statusCode != 200) {
        debugPrint(
          '[AuthenticatedImageProvider] Failed to load image: ${response.statusCode}',
        );
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: Uri.parse(key.url),
        );
      }

      debugPrint('[AuthenticatedImageProvider] Image loaded successfully');
      final bytes = response.bodyBytes;

      if (bytes.isEmpty) {
        throw Exception('Image is empty');
      }

      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (e) {
      debugPrint('[AuthenticatedImageProvider] Error loading image: $e');
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AuthenticatedImageProvider &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'AuthenticatedImageProvider')}("$url", scale: $scale)';
}
