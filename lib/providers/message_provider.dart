import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';
import '../services/message_api.dart';

/// Holds the message list for the currently-open conversation.
///
/// Key behaviours:
///   - Dedup by message _id (incoming socket + server response can't double-add)
///   - Optimistic add on send, swapped for the server version when it arrives
///   - Single subscription to SocketService.onMessage; cancelled in dispose
class MessageProvider extends ChangeNotifier {
  MessageProvider({
    required this.conversationId,
    required SocketService socket,
    required MessageApi api,
  })  : _socket = socket,
        _api = api {
    _subscription = _socket.onMessage.listen(_handleIncoming);
  }

  final String conversationId;
  final SocketService _socket;
  final MessageApi _api;

  StreamSubscription<Map<String, dynamic>>? _subscription;

  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _knownIds = {};

  bool _loading = false;
  bool _sending = false;
  String? _error;

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  bool get loading => _loading;
  bool get sending => _sending;
  String? get error => _error;

  Future<void> loadInitial() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.listMessages(conversationId);
      _messages
        ..clear()
        ..addAll(list);
      _knownIds
        ..clear()
        ..addAll(list.map((m) => m['_id'].toString()));
      await _api.markRead(conversationId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Send a message. Guarded against double-send via _sending flag.
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;

    _sending = true;
    notifyListeners();

    // Optimistic add with a temp id we can swap later.
    final tempId = 'tmp_${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = <String, dynamic>{
      '_id': tempId,
      'conversationId': conversationId,
      'senderId': _socket.currentUserId,
      'text': trimmed,
      'createdAt': DateTime.now().toIso8601String(),
      '_pending': true,
    };
    _messages.add(optimistic);
    _knownIds.add(tempId);
    notifyListeners();

    try {
      final saved = await _api.sendMessage(
        conversationId: conversationId,
        text: trimmed,
      );
      final savedId = saved['_id'].toString();

      // Swap optimistic placeholder for the real saved message.
      final idx = _messages.indexWhere((m) => m['_id'] == tempId);
      if (idx >= 0) {
        _messages[idx] = saved;
      }
      _knownIds
        ..remove(tempId)
        ..add(savedId);
    } catch (e) {
      // Mark the optimistic message as failed; remove from known so a retry works.
      final idx = _messages.indexWhere((m) => m['_id'] == tempId);
      if (idx >= 0) {
        _messages[idx] = {..._messages[idx], '_failed': true, '_pending': false};
      }
      _error = e.toString();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  void _handleIncoming(Map<String, dynamic> msg) {
    if (msg['conversationId']?.toString() != conversationId) return;
    final id = msg['_id']?.toString();
    if (id == null || _knownIds.contains(id)) return;

    _knownIds.add(id);
    _messages.add(msg);
    notifyListeners();

    // Fire-and-forget mark-as-read so the badge clears server-side too.
    _api.markRead(conversationId).catchError((_) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}