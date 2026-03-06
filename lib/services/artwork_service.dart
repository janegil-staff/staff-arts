// lib/services/artwork_service.dart
import '../config/api_config.dart';
import '../models/artwork_model.dart';
import 'api_service.dart';

class ArtworkService {
  final ApiService _api = ApiService();

  Future<List<ArtworkModel>> getArtworks({
    int page = 1,
    int limit = 20,
    String? status,
    bool? forSale,
    String? category,
    String? artist,
  }) async {
    final res = await _api.get(ApiConfig.artworks, params: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (forSale != null) 'forSale': forSale,
      if (category != null) 'category': category,
      if (artist != null) 'artist': artist,
    });
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load artworks');
    return (body['data'] as List)
        .map((e) => ArtworkModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ArtworkModel> getArtwork(String id) async {
    final res = await _api.get(ApiConfig.artwork(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load artwork');
    return ArtworkModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ArtworkModel> createArtwork(Map<String, dynamic> data) async {
    final res = await _api.post(ApiConfig.artworks, data: data);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to create artwork');
    return ArtworkModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ArtworkModel> updateArtwork(String id, Map<String, dynamic> data) async {
    final res = await _api.put(ApiConfig.artwork(id), data: data);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to update artwork');
    return ArtworkModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteArtwork(String id) async {
    final res = await _api.delete(ApiConfig.artwork(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to delete artwork');
  }

  Future<Map<String, dynamic>> toggleLike(String id) async {
    final res = await _api.post(ApiConfig.artworkLike(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to like artwork');
    return Map<String, dynamic>.from(body['data']);
  }

  Future<Map<String, dynamic>> toggleSave(String id) async {
    final res = await _api.post(ApiConfig.artworkSave(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to save artwork');
    return Map<String, dynamic>.from(body['data']);
  }
}
