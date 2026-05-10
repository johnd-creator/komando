import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komando/core/api/api_error_handler.dart';

void main() {
  group('ApiErrorHandler', () {
    test('connectionTimeout returns Indonesian message', () {
      final error = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(),
      );
      final message = ApiErrorHandler.getMessage(error);
      expect(message, contains('timeout'));
      expect(message, contains('koneksi'));
    });

    test('connectionError returns offline message', () {
      final error = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(),
      );
      final message = ApiErrorHandler.getMessage(error);
      expect(message, 'Tidak ada koneksi internet.');
    });

    test('401 returns session expired message', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(), statusCode: 401),
        requestOptions: RequestOptions(),
      );
      final message = ApiErrorHandler.getMessage(error);
      expect(message, 'Sesi Anda berakhir. Silakan login kembali.');
    });

    test('403 returns access denied message', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(), statusCode: 403),
        requestOptions: RequestOptions(),
      );
      final message = ApiErrorHandler.getMessage(error);
      expect(message, 'Anda tidak memiliki akses ke fitur ini.');
    });

    test('bad response uses backend message when available', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 403,
          data: {'message': 'Anda tidak memiliki akses kelola unit tersebut.'},
        ),
        requestOptions: RequestOptions(),
      );
      final message = ApiErrorHandler.getMessage(error);
      expect(message, 'Anda tidak memiliki akses kelola unit tersebut.');
    });

    test('404 returns not found message', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
        requestOptions: RequestOptions(),
      );
      final message = ApiErrorHandler.getMessage(error);
      expect(message, 'Data tidak ditemukan.');
    });

    test('422 returns validation message', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(), statusCode: 422),
        requestOptions: RequestOptions(),
      );
      final message = ApiErrorHandler.getMessage(error);
      expect(message, 'Periksa kembali data yang Anda isi.');
    });

    test('429 returns rate limit message', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(), statusCode: 429),
        requestOptions: RequestOptions(),
      );
      final message = ApiErrorHandler.getMessage(error);
      expect(message, 'Terlalu banyak percobaan. Coba lagi nanti.');
    });

    test('500 returns server error message', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(), statusCode: 500),
        requestOptions: RequestOptions(),
      );
      final message = ApiErrorHandler.getMessage(error);
      expect(message, 'Server sedang bermasalah. Silakan coba lagi.');
    });

    test('501 returns mobile google login not enabled message', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(), statusCode: 501),
        requestOptions: RequestOptions(),
      );
      final message = ApiErrorHandler.getMessage(error);
      expect(message, 'Login Google mobile belum aktif di server.');
    });

    test('non-Dio error returns generic message', () {
      final message = ApiErrorHandler.getMessage(Exception('test'));
      expect(message, 'Terjadi kesalahan. Silakan coba lagi.');
    });
  });
}
