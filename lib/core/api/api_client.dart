import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import '../constants/api_constants.dart';
import '../security/token_storage.dart';

class ApiClient {
  ApiClient({Dio? dio, TokenStorage? tokenStorage})
    : tokenStorage = tokenStorage ?? TokenStorage(),
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.mobileApiBaseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 60),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          ) {
    // 1. Auth interceptor — must run first so token is attached before retry
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip auth header injection for login/token-exchange endpoints.
          // Sending a stale token on these endpoints can cause the backend
          // to treat the request as already-authenticated and reject it.
          final skipAuth = options.extra['skipAuth'] == true;
          if (!skipAuth) {
            final token = await this.tokenStorage.readAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } else {
            // Ensure no Authorization header leaks through (e.g. from BaseOptions)
            options.headers.remove('Authorization');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await this.tokenStorage.clearAccessToken();
          }
          handler.next(error);
        },
      ),
    );

    // 2. Retry interceptor — retries transient network errors and 5xx responses
    this.dio.interceptors.add(
      RetryInterceptor(
        dio: this.dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryEvaluator: (error, attempt) {
          // Retry on network errors and 502/503/504 (transient server errors)
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            return true;
          }
          final statusCode = error.response?.statusCode;
          return statusCode == 502 || statusCode == 503 || statusCode == 504;
        },
      ),
    );
  }

  final Dio dio;
  final TokenStorage tokenStorage;
}
