import 'package:dio/dio.dart';

class WordpressClient {
  WordpressClient() : _dio = Dio(BaseOptions(
    baseUrl: 'https://sppips.org/wp-json/wp/v2',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final Dio _dio;

  Dio get dio => _dio;
}
