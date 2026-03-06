// lib/services/event_service.dart
import '../config/api_config.dart';
import '../models/event_model.dart';
import 'api_service.dart';

class EventService {
  final ApiService _api = ApiService();

  Future<List<EventModel>> getEvents({
    String? type,
    String? category,
    bool? upcoming,
  }) async {
    final res = await _api.get(ApiConfig.events, params: {
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (upcoming != null) 'upcoming': upcoming,
    });
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load events');
    return (body['data'] as List)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EventModel> getEvent(String id) async {
    final res = await _api.get(ApiConfig.event(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load event');
    return EventModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<EventModel> createEvent(Map<String, dynamic> data) async {
    final res = await _api.post(ApiConfig.events, data: data);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to create event');
    return EventModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<EventModel> updateEvent(String id, Map<String, dynamic> data) async {
    final res = await _api.put(ApiConfig.event(id), data: data);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to update event');
    return EventModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteEvent(String id) async {
    final res = await _api.delete(ApiConfig.event(id));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to delete event');
  }

  Future<Map<String, dynamic>> toggleRsvp(String id) async {
    final res = await _api.post('${ApiConfig.event(id)}/rsvp');
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to RSVP');
    return Map<String, dynamic>.from(body['data']);
  }
}
