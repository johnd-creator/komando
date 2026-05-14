import 'package:dio/dio.dart';

class ApiErrorHandler {
  const ApiErrorHandler._();

  static String getMessage(Object error) {
    if (error is! DioException) {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa koneksi internet Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet.';
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return 'Data gagal dimuat. Silakan coba lagi.';
    }
  }

  static String _handleBadResponse(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final validationMessage = _firstValidationMessage(data['errors']);
      if (validationMessage != null) {
        return validationMessage;
      }

      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return _handleStatus(response?.statusCode);
  }

  static String? _firstValidationMessage(Object? errors) {
    if (errors is! Map) return null;

    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) {
        final first = value.first;
        if (first is String && first.trim().isNotEmpty) {
          return first;
        }
      }

      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  static String _handleStatus(int? statusCode) {
    if (statusCode == null) {
      return 'Data gagal dimuat. Silakan coba lagi.';
    }

    return switch (statusCode) {
      401 => 'Sesi Anda berakhir. Silakan login kembali.',
      403 => 'Anda tidak memiliki akses ke fitur ini.',
      404 => 'Data tidak ditemukan.',
      // 422 on login = wrong credentials. The backend message is shown first
      // (via _handleBadResponse), this fallback is only reached if no message.
      422 => 'Email atau password salah. Silakan periksa kembali.',
      429 => 'Terlalu banyak percobaan. Coba lagi nanti.',
      501 => 'Login Google mobile belum aktif di server.',
      >= 500 => 'Server sedang bermasalah. Silakan coba lagi.',
      _ => 'Data gagal dimuat. Silakan coba lagi.',
    };
  }
}
