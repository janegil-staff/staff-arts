// lib/services/exhibition_service.dart
import '../config/api_config.dart';
import '../models/exhibition_model.dart';
import 'api_service.dart';

class ExhibitionService {
  final ApiService _api = ApiService();

  Future<List<ExhibitionModel>> getExhibitions() async {
    final res = await _api.get(ApiConfig.exhibitions);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load exhibitions');
    return (body['data'] as List)
        .map((e) => ExhibitionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExhibitionModel> getExhibition(String id) async {
    final res = await _api.get(ApiConfig.exhibition(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load exhibition');
    return ExhibitionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ExhibitionModel> createExhibition(Map<String, dynamic> data) async {
    final res = await _api.post(ApiConfig.exhibitions, data: data);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to create exhibition');
    return ExhibitionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ExhibitionModel> updateExhibition(String id, Map<String, dynamic> data) async {
    final res = await _api.put(ApiConfig.exhibition(id), data: data);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to update exhibition');
    return ExhibitionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteExhibition(String id) async {
    final res = await _api.delete(ApiConfig.exhibition(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to delete exhibition');
  }

  Future<Map<String, dynamic>> toggleAttend(String id) async {
    final res = await _api.post('${ApiConfig.exhibition(id)}/attend');
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to update attendance');
    return Map<String, dynamic>.from(body['data']);
  }
}
