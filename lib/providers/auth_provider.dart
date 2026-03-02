// lib/providers/auth_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _error;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> checkAuth() async {
    final token = await _apiService.getToken();
    print('TOKEN: $token'); // debug
    if (token == null) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user = await _authService.getMe();
      print('USER: ${_user?.email}'); // debug
      _state = AuthState.authenticated;
    } catch (e) {
      print('AUTH CHECK FAILED: $e'); // debug
      _state = AuthState.unauthenticated;
      await _apiService.clearTokens();
    }
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      _user = await _authService.getMe();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.login(email, password);
      _user = result.user;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? displayName,
    String role = 'collector',
  }) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      );
      _user = result.user;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) return data['error'];
      if (e.response?.statusCode == 401) return 'Invalid credentials';
      if (e.response?.statusCode == 409) return 'Email already in use';
      return 'Network error. Please try again.';
    }
    if (e is Exception) return e.toString().replaceFirst('Exception: ', '');
    return 'Something went wrong';
  }
}
