// lib/services/api_service.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// If a refresh is currently in flight, all other 401-triggered refresh
  /// attempts await this future instead of firing their own request.
  /// This prevents the "rotated-token race" that 401s the loser requests.
  Future<bool>? _refreshInFlight;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: defaultTargetPlatform == TargetPlatform.android
          ? ApiConfig.androidEmulatorUrl
          : ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Don't attach the (possibly expired) access token to the refresh call.
        if (options.path != ApiConfig.refreshToken) {
          final token = await _storage.read(key: "token");
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
        }
        // Let Dio set the correct Content-Type for FormData (multipart)
        if (options.data is FormData) {
          options.headers.remove("Content-Type");
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isRefreshCall =
            error.requestOptions.path == ApiConfig.refreshToken;

        if (error.response?.statusCode == 401 &&
            !isRefreshCall &&
            error.requestOptions.extra["retried"] != true) {
          error.requestOptions.extra["retried"] = true;

          final refreshed = await _coalescedRefresh();

          if (refreshed) {
            final token = await _storage.read(key: "token");
            error.requestOptions.headers["Authorization"] = "Bearer $token";
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

  /// Coalesces concurrent refresh attempts into a single request.
  /// If a refresh is already running, awaits its result instead of starting
  /// another (which would 401 because the refresh token was just rotated).
  Future<bool> _coalescedRefresh() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final future = _tryRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
    _refreshInFlight = future;
    return future;
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.read(key: "refreshToken");
    if (refreshToken == null) return false;
    try {
      final res = await _dio.post(ApiConfig.refreshToken, data: {
        "refreshToken": refreshToken,
      });
      if (res.data["success"] == true) {
        final data = res.data["data"] as Map<String, dynamic>;
        await saveTokens(
          token: data["accessToken"],
          refreshToken: data["refreshToken"],
        );
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 REFRESH FAILED: $e');
      }
    }
    return false;
  }

  Future<void> saveTokens(
      {required String token, required String refreshToken}) async {
    await _storage.write(key: "token", value: token);
    await _storage.write(key: "refreshToken", value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: "token");
    await _storage.delete(key: "refreshToken");
  }

  Future<String?> getToken() async {
    return await _storage.read(key: "token");
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

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}