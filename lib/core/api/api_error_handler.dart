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
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return _handleStatus(response?.statusCode);
  }

  static String _handleStatus(int? statusCode) {
    if (statusCode == null) {
      return 'Data gagal dimuat. Silakan coba lagi.';
    }

    return switch (statusCode) {
      401 => 'Sesi Anda berakhir. Silakan login kembali.',
      403 => 'Anda tidak memiliki akses ke fitur ini.',
      404 => 'Data tidak ditemukan.',
      422 => 'Periksa kembali data yang Anda isi.',
      429 => 'Terlalu banyak percobaan. Coba lagi nanti.',
      501 => 'Login Google mobile belum aktif di server.',
      >= 500 => 'Server sedang bermasalah. Silakan coba lagi.',
      _ => 'Data gagal dimuat. Silakan coba lagi.',
    };
  }
}
