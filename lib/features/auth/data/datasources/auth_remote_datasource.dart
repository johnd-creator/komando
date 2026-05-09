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
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password, 'device_name': deviceName},
    );

    final data = response.data ?? <String, dynamic>{};
    return (
      accessToken: data['access_token'] as String? ?? '',
      user: AppUserModel.fromJson(data['user'] as Map<String, dynamic>? ?? {}),
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

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/google/token',
      data: body,
    );

    final data = response.data ?? <String, dynamic>{};
    return (
      accessToken: data['access_token'] as String? ?? '',
      user: AppUserModel.fromJson(data['user'] as Map<String, dynamic>? ?? {}),
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
