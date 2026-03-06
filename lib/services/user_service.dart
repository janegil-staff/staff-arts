// lib/services/user_service.dart
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/artwork_model.dart';
import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<List<UserModel>> getUsers({
    String? role,
    bool? featured,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get(ApiConfig.users, params: {
      'page': page,
      'limit': limit,
      if (role != null) 'role': role,
      if (featured != null) 'featured': featured,
    });
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load users');
    return (body['data'] as List)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> getUserById(String id) async {
    final res = await _api.get(ApiConfig.user(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'User not found');
    return UserModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<UserModel> getUserByUsername(String username) async {
    final res = await _api.get(ApiConfig.userByUsername(username));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'User not found');
    return UserModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _api.put(ApiConfig.user(id), data: data);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to update user');
    return UserModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> toggleFollow(String id) async {
    final res = await _api.post(ApiConfig.userFollow(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to follow user');
    return Map<String, dynamic>.from(body['data']);
  }

  Future<List<ArtworkModel>> getUserArtworks(String id) async {
    final res = await _api.get('${ApiConfig.user(id)}/artworks');
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load artworks');
    return (body['data'] as List)
        .map((e) => ArtworkModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
