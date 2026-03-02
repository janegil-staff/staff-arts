// lib/services/auth_service.dart
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthResult {
  final UserModel user;
  final String token;
  final String refreshToken;
  AuthResult({required this.user, required this.token, required this.refreshToken});
}

class AuthService {
  final ApiService _api = ApiService();

  Future<AuthResult> login(String email, String password) async {
    final res = await _api.post(ApiConfig.login, data: {
      'email': email,
      'password': password,
    });
    final body = res.data;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Login failed');
    }
    final data = body['data'];
    await _api.saveTokens(token: data['token'], refreshToken: data['refreshToken']);
    return AuthResult(
      user: UserModel.fromJson(data['user']),
      token: data['token'],
      refreshToken: data['refreshToken'],
    );
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? displayName,
    String role = 'collector',
  }) async {
    final res = await _api.post(ApiConfig.register, data: {
      'name': name,
      'email': email,
      'password': password,
      if (displayName != null) 'displayName': displayName,
      'role': role,
    });
    final body = res.data;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Registration failed');
    }
    final data = body['data'];
    await _api.saveTokens(token: data['token'], refreshToken: data['refreshToken']);
    return AuthResult(
      user: UserModel.fromJson(data['user']),
      token: data['token'],
      refreshToken: data['refreshToken'],
    );
  }

  Future<UserModel> getMe() async {
    final res = await _api.get(ApiConfig.me);
    final body = res.data;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Failed to fetch profile');
    }
    return UserModel.fromJson(body['data']);
  }

  Future<void> logout() async {
    await _api.clearTokens();
  }
}