// lib/services/shows_service.dart
import '../config/api_config.dart';
import 'api_service.dart';

class ShowsService {
  final _api = ApiService();

  Future<List<dynamic>> fetchEvents() async {
    try {
      final res = await _api.get(ApiConfig.events);
      final data = res.data as Map<String, dynamic>;
      return (data['events'] ?? data['data']?['events'] ?? []) as List<dynamic>;
    } catch (e) {
      print('Shows events error: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchExhibitions() async {
    try {
      final res = await _api.get(ApiConfig.exhibitions);
      final data = res.data as Map<String, dynamic>;
      return (data['exhibitions'] ?? data['data']?['exhibitions'] ?? [])
          as List<dynamic>;
    } catch (e) {
      print('Shows exhibitions error: $e');
      return [];
    }
  }
}