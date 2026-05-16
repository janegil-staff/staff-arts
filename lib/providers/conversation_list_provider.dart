import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';
import '../services/conversation_api.dart';

class ConversationListProvider extends ChangeNotifier {
  ConversationListProvider({
    required SocketService socket,
    required ConversationApi api,
  })  : _socket = socket,
        _api = api {
    _subscription = _socket.onMessage.listen(_handleIncoming);
  }

  final SocketService _socket;
  final ConversationApi _api;

  StreamSubscription<Map<String, dynamic>>? _subscription;

  final List<Map<String, dynamic>> _conversations = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get conversations =>
      List.unmodifiable(_conversations);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.listConversations();
      _conversations
        ..clear()
        ..addAll(list);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  /// Called when the user opens a conversation — zero its unread on screen
  /// (server-side mark-read happens in MessageProvider.loadInitial).
  void markReadLocally(String conversationId) {
    final idx = _conversations.indexWhere(
      (c) => c['_id'].toString() == conversationId,
    );
    if (idx < 0) return;
    final current = _conversations[idx];
    if ((current['unread'] ?? 0) == 0) return;
    _conversations[idx] = {...current, 'unread': 0};
    notifyListeners();
  }

  void _handleIncoming(Map<String, dynamic> msg) {
    final convId = msg['conversationId']?.toString();
    if (convId == null) return;

    final senderId = msg['senderId']?.toString();
    final isMine = senderId == _socket.currentUserId;

    final idx = _conversations.indexWhere(
      (c) => c['_id'].toString() == convId,
    );

    if (idx < 0) {
      // New conversation we haven't loaded yet — refetch the list.
      load();
      return;
    }

    final existing = _conversations[idx];
    final currentUnread = (existing['unread'] ?? 0) as int;
    final updated = {
      ...existing,
      'lastMessageText': msg['text'] ?? existing['lastMessageText'],
      'lastMessageAt': msg['createdAt'] ?? existing['lastMessageAt'],
      'lastMessageSenderId': senderId ?? existing['lastMessageSenderId'],
      // Only bump unread for messages from someone else.
      'unread': isMine ? currentUnread : currentUnread + 1,
    };

    // Move to top.
    _conversations
      ..removeAt(idx)
      ..insert(0, updated);

    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}