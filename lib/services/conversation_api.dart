import 'dart:convert';
import 'package:http/http.dart' as http;

class ConversationApi {
  ConversationApi({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// GET /api/conversations
  Future<List<Map<String, dynamic>>> listConversations() async {
    final uri = Uri.parse('$baseUrl/api/conversations');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load conversations (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] as List).cast<Map<String, dynamic>>();
    return data;
  }

  /// POST /api/conversations  body: { otherUserId }
  Future<Map<String, dynamic>> getOrCreate(String otherUserId) async {
    final uri = Uri.parse('$baseUrl/api/conversations');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'otherUserId': otherUserId}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to start conversation (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['data'] ?? body) as Map<String, dynamic>;
  }
}