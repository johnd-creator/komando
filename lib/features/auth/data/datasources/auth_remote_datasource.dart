import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/app_user_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<({String accessToken, AppUserModel user})> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    // Explicitly exclude Authorization header for login requests.
    // A stale token in storage must not be forwarded to the login endpoint,
    // as some backends reject authenticated requests on /auth/login.
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password, 'device_name': deviceName},
      options: Options(
        headers: {'Authorization': null},
        extra: {'skipAuth': true},
      ),
    );

    final data = response.data ?? <String, dynamic>{};
    final token = data['access_token'] as String? ?? '';
    final userJson = data['user'];
    if (token.isEmpty) {
      throw Exception('Access token kosong dari server.');
    }
    return (
      accessToken: token,
      user: AppUserModel.fromJson(
        userJson is Map<String, dynamic> ? userJson : {},
      ),
    );
  }

  Future<AppUserModel> me() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/me');
    final data = response.data ?? <String, dynamic>{};
    return AppUserModel.fromJson(data);
  }

  Future<({String accessToken, AppUserModel user})> googleLogin({
    required String idToken,
    String? serverAuthCode,
  }) async {
    final body = <String, dynamic>{
      'id_token': idToken,
      'device_name': 'flutter',
    };
    final code = serverAuthCode;
    if (code != null) {
      body['server_auth_code'] = code;
    }

    // Also exclude Authorization header for Google token exchange.
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/google/token',
      data: body,
      options: Options(
        headers: {'Authorization': null},
        extra: {'skipAuth': true},
      ),
    );

    final data = response.data ?? <String, dynamic>{};
    final token = data['access_token'] as String? ?? '';
    final userJson = data['user'];
    if (token.isEmpty) {
      throw Exception('Access token kosong dari server.');
    }
    return (
      accessToken: token,
      user: AppUserModel.fromJson(
        userJson is Map<String, dynamic> ? userJson : {},
      ),
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post<void>('/auth/logout');
    } on DioException {
      rethrow;
    }
  }
}
