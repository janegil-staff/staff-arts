// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: defaultTargetPlatform == TargetPlatform.android
          ? ApiConfig.androidEmulatorUrl
          : ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer \$token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isRefreshCall = error.requestOptions.path == ApiConfig.refreshToken;
        if (error.response?.statusCode == 401 &&
            !isRefreshCall &&
            error.requestOptions.extra['retried'] != true) {
          error.requestOptions.extra['retried'] = true;
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final token = await _storage.read(key: 'token');
            error.requestOptions.headers['Authorization'] = 'Bearer \$token';
            try {
              final res = await _dio.fetch(error.requestOptions);
              return handler.resolve(res);
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken == null) return false;
    try {
      final res = await _dio.post(ApiConfig.refreshToken, data: {
        'refreshToken': refreshToken,
      });
      if (res.data['success'] == true) {
        await saveTokens(
          token: res.data['data']['token'],
          refreshToken: res.data['data']['refreshToken'],
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> saveTokens({required String token, required String refreshToken}) async {
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refreshToken');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) {
    return _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
