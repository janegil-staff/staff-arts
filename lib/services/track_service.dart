// lib/services/track_service.dart
import '../config/api_config.dart';
import '../models/track_model.dart';
import 'api_service.dart';

class TrackService {
  final ApiService _api = ApiService();

  Future<List<TrackModel>> getTracks() async {
    final res = await _api.get(ApiConfig.tracks);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load tracks');
    return (body['data'] as List)
        .map((e) => TrackModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TrackModel> getTrack(String id) async {
    final res = await _api.get(ApiConfig.track(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load track');
    return TrackModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<TrackModel> createTrack(Map<String, dynamic> data) async {
    final res = await _api.post(ApiConfig.tracks, data: data);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to create track');
    return TrackModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<TrackModel> updateTrack(String id, Map<String, dynamic> data) async {
    final res = await _api.put(ApiConfig.track(id), data: data);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to update track');
    return TrackModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTrack(String id) async {
    final res = await _api.delete(ApiConfig.track(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to delete track');
  }
}
