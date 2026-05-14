import 'package:dio/dio.dart';

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
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          ) {
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
  }

  final Dio dio;
  final TokenStorage tokenStorage;
}
