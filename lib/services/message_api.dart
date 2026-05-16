import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin HTTP client for the conversation/message endpoints.
/// Adjust _baseUrl + auth header to match the rest of your app.
class MessageApi {
  MessageApi({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// GET /api/conversations/:id/messages
  Future<List<Map<String, dynamic>>> listMessages(String conversationId) async {
    final uri = Uri.parse('$baseUrl/api/conversations/$conversationId/messages');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load messages (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] as List).cast<Map<String, dynamic>>();
    return data;
  }

  /// POST /api/conversations/messages  body: { conversationId, text }
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final uri = Uri.parse('$baseUrl/api/conversations/messages');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'conversationId': conversationId, 'text': text}),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to send message (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] ?? body) as Map<String, dynamic>;
  }

  /// POST /api/conversations/:id/read
  Future<void> markRead(String conversationId) async {
    final uri = Uri.parse('$baseUrl/api/conversations/$conversationId/read');
    await http.post(uri, headers: _headers);
  }
}