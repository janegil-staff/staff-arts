// lib/services/shows_service.dart
import '../config/api_config.dart';
import 'api_service.dart';

class ShowsService {
  final _api = ApiService();

  Future<List<dynamic>> fetchEvents() async {
    try {
      final res = await _api.get(ApiConfig.events);
      final body = res.data as Map<String, dynamic>;
      if (body['success'] != true) return [];
      // ✅ data is the list directly — { success: true, data: [...] }
      return (body['data'] as List<dynamic>? ?? []);
    } catch (e) {
      print('Shows events error: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchExhibitions() async {
    try {
      final res = await _api.get(ApiConfig.exhibitions);
      final body = res.data as Map<String, dynamic>;
      if (body['success'] != true) return [];
      // ✅ same fix
      return (body['data'] as List<dynamic>? ?? []);
    } catch (e) {
      print('Shows exhibitions error: $e');
      return [];
    }
  }
}
