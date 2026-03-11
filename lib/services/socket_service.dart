// lib/services/socket_service.dart
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';
import '../config/api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  final _api = ApiService();

  // Stored callbacks by key — re-bound after reconnect
  final Map<String, void Function(Map<String, dynamic>)> _callbacks = {};
  // Actual bound handlers by key
  final Map<String, void Function(dynamic)> _handlers = {};

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    if (isConnected) {
      _joinAllRooms();
      return;
    }

    // If socket exists but disconnected, reconnect it
    if (_socket != null) {
      _socket!.connect();
      return;
    }

    final token = await _api.getToken();
    if (token == null) return;

    _socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('🔌 Socket connected');
      _reBindAllListeners();
      _joinAllRooms();
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 Socket disconnected');
    });

    _socket!.onConnectError((e) {
      debugPrint('🔌 Socket connect error: $e');
    });

    _socket!.on('reconnect', (_) {
      debugPrint('🔌 Socket reconnected');
      _reBindAllListeners();
      _joinAllRooms();
    });

    _socket!.connect();
  }

  void _reBindAllListeners() {
    // Remove all old handlers
    for (final h in _handlers.values) {
      _socket?.off('new_message', h);
    }
    _handlers.clear();

    // Re-bind all stored callbacks
    for (final entry in _callbacks.entries) {
      void handler(dynamic data) {
        if (data is Map<String, dynamic>) entry.value(data);
      }

      _handlers[entry.key] = handler;
      _socket?.on('new_message', handler);
    }
    debugPrint('🔌 Re-bound ${_callbacks.length} listeners');
  }

  Future<void> _joinAllRooms() async {
    try {
      final res = await _api.get(ApiConfig.conversations);
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] is List) {
        for (final c in body['data'] as List) {
          if (c is Map) {
            final id = (c['_id'] ?? c['id'])?.toString();
            if (id != null) _socket?.emit('join_conversation', id);
          }
        }
        debugPrint('🔌 Joined all conversation rooms');
      }
    } catch (e) {
      debugPrint('🔌 Failed to join rooms: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _handlers.clear();
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', conversationId);
  }

  void addMessageListener(
      String key, void Function(Map<String, dynamic>) callback) {
    // Remove existing handler for this key
    if (_handlers.containsKey(key)) {
      _socket?.off('new_message', _handlers[key]);
      _handlers.remove(key);
    }

    // Store callback for rebinding after reconnect
    _callbacks[key] = callback;

    // Bind now
    void handler(dynamic data) {
      if (data is Map<String, dynamic>) callback(data);
    }

    _handlers[key] = handler;
    _socket?.on('new_message', handler);
  }

  void removeMessageListener(String key) {
    _callbacks.remove(key);
    final handler = _handlers.remove(key);
    if (handler != null) _socket?.off('new_message', handler);
  }

  // Per-conversation listener (used in chat_screen)
  void onNewMessage(
      String conversationId, void Function(Map<String, dynamic>) callback) {
    addMessageListener('__convo_$conversationId', (data) {
      final msgConvoId = data['conversation']?.toString() ?? '';
      if (msgConvoId == conversationId) callback(data);
    });
  }

  void offNewMessage() {
    // Remove all per-convo listeners
    _callbacks.keys
        .where((k) => k.startsWith('__convo_'))
        .toList()
        .forEach(removeMessageListener);
  }

  void onReconnect(void Function() callback) {
    _socket?.on('reconnect', (_) => callback());
  }

  void onAnyMessage(void Function(Map<String, dynamic>) callback) =>
      addMessageListener('__global__', callback);

  void offAnyMessage() => removeMessageListener('__global__');
}
