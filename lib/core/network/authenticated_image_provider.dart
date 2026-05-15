import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logging/app_logger.dart';
import '../security/token_storage.dart';

/// Custom image provider that fetches images with Bearer auth headers.
/// Uses Dio (already a project dependency) instead of package:http.
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

  // Shared Dio instance for image fetching — no auth interceptor needed here,
  // we inject the token manually per request.
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

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
      AppLogger.d('Loading authenticated image', tag: 'ImageProvider');

      final token = await tokenStorage.readAccessToken();
      final headers = <String, String>{'Accept': 'image/*'};

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.get<Uint8List>(
        key.url,
        options: Options(headers: headers, responseType: ResponseType.bytes),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode != 200) {
        AppLogger.w('Image load failed: $statusCode', tag: 'ImageProvider');
        throw NetworkImageLoadException(
          statusCode: statusCode,
          uri: Uri.parse(key.url),
        );
      }

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Image is empty');
      }

      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (e) {
      AppLogger.e('Error loading image', error: e, tag: 'ImageProvider');
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
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
