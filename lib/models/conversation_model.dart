// lib/models/conversation_model.dart

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final Map<String, dynamic>? sender;
  final String text;
  final List<String> readBy;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.sender,
    required this.text,
    this.readBy = const [],
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final senderRaw = json['sender'];
    return MessageModel(
      id: json['id'] ?? json['_id'] ?? '',
      conversationId: json['conversation'] ?? '',
      senderId: senderRaw is Map
          ? (senderRaw['id'] ?? senderRaw['_id'] ?? '')
          : (senderRaw ?? ''),
      sender:
          senderRaw is Map ? Map<String, dynamic>.from(senderRaw) : null,
      text: json['text'] ?? '',
      readBy: List<String>.from(json['readBy'] ?? []),
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ConversationModel {
  final String id;
  final List<Map<String, dynamic>> participants;
  final MessageModel? lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    this.participants = const [],
    this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? json['_id'] ?? '',
      participants: (json['participants'] as List? ?? [])
          .map((p) =>
              p is Map ? Map<String, dynamic>.from(p) : <String, dynamic>{})
          .toList(),
      lastMessage: json['lastMessage'] is Map
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      lastMessageAt: DateTime.parse(
          json['lastMessageAt'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
