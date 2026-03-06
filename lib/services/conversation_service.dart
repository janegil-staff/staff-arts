// lib/services/conversation_service.dart
import '../config/api_config.dart';
import '../models/conversation_model.dart';
import 'api_service.dart';

class ConversationService {
  final ApiService _api = ApiService();

  Future<List<ConversationModel>> getConversations() async {
    final res = await _api.get(ApiConfig.conversations);
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load conversations');
    return (body['data'] as List)
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConversationModel> getOrCreateConversation(String participantId) async {
    final res = await _api.post(ApiConfig.conversations, data: {
      'participantId': participantId,
    });
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to create conversation');
    return ConversationModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final res = await _api.get(ApiConfig.messages(conversationId));
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to load messages');
    return (body['data'] as List)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MessageModel> sendMessage(String conversationId, String text) async {
    final res = await _api.post(ApiConfig.messages(conversationId), data: {
      'text': text,
    });
    final body = res.data;
    if (body['success'] != true) throw Exception(body['error'] ?? 'Failed to send message');
    return MessageModel.fromJson(body['data'] as Map<String, dynamic>);
  }
}
