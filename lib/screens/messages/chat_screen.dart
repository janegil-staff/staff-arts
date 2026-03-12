// lib/screens/messages/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String name;
  final String? participantId;
  final String? initialMessage;

  const ChatScreen({
    super.key,
    this.conversationId,
    required this.name,
    this.participantId,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService();
  final _socket = SocketService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _convoId;

  @override
  void initState() {
    super.initState();
    _convoId = widget.conversationId;
    if (widget.initialMessage != null) {
      _controller.text = widget.initialMessage!;
    }
    _initChat();
  }

  Future<void> _initChat() async {
    await _socket.connect();
    if (_convoId != null) {
      await _load();
      _socket.joinConversation(_convoId!);
      _socket.onNewMessage(_convoId!, _onSocketMessage);
    } else {
      setState(() => _loading = false);
    }
  }

  void _onSocketMessage(Map<String, dynamic> msg) {
    final myId = context.read<AuthProvider>().user?.id ?? '';
    final senderId = _extractSenderId(msg);
    if (senderId == myId) return;
    if (mounted) {
      setState(() => _messages.add(msg));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    if (_convoId != null) {
      _socket.removeMessageListener('__convo_${_convoId!}');
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_convoId == null) return;
    try {
      final res = await _api.get(ApiConfig.messages(_convoId!));
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] is List) {
        setState(
            () => _messages = List<Map<String, dynamic>>.from(body['data']));
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      debugPrint('Chat load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);

    try {
      if (_convoId == null && widget.participantId != null) {
        final convoRes = await _api.post(ApiConfig.conversations, data: {
          'participantId': widget.participantId,
        });
        final convoData = convoRes.data['data'] as Map<String, dynamic>;
        _convoId = (convoData['_id'] ?? convoData['id']).toString();
        await _socket.connect();
        _socket.joinConversation(_convoId!);
        _socket.onNewMessage(_convoId!, _onSocketMessage);
      }

      if (_convoId == null) return;

      final myUser = context.read<AuthProvider>().user;
      final optimistic = {
        '_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'text': text,
        'sender': {
          '_id': myUser?.id ?? '',
          'displayName': myUser?.displayName ?? myUser?.name ?? '',
          'avatar': myUser?.avatar,
        },
        'createdAt': DateTime.now().toIso8601String(),
        'readBy': [myUser?.id ?? ''],
      };
      setState(() => _messages.add(optimistic));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      final res =
          await _api.post(ApiConfig.messages(_convoId!), data: {'text': text});
      final sent = res.data['data'] as Map<String, dynamic>;

      setState(() {
        final idx = _messages.indexWhere((m) => m['_id'] == optimistic['_id']);
        if (idx != -1) _messages[idx] = sent;
      });
    } catch (e) {
      debugPrint('Chat send error: $e');
      setState(() => _messages.removeWhere(
          (m) => m['_id']?.toString().startsWith('temp_') == true));
    }
    if (mounted) setState(() => _sending = false);
  }

  String _extractSenderId(Map<String, dynamic> msg) {
    final sender = msg['sender'];
    if (sender is Map) return (sender['_id'] ?? sender['id'] ?? '').toString();
    return (sender ?? msg['senderId'] ?? '').toString();
  }

  String _formatTime(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final d = DateTime.parse(dateVal.toString());
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().user?.id ?? '';
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(widget.name,
            style: const TextStyle(fontWeight: FontWeight.w300)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.teal))
              : _messages.isEmpty
                  ? Center(
                      child: Text('Start a conversation with ${widget.name}',
                          style: const TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.textMuted)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final msg = _messages[i];
                        final senderId = _extractSenderId(msg);
                        return _bubble(msg, senderId == myId);
                      },
                    ),
        ),
        Container(
          padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 10,
              bottom: bottomPadding > 0 ? bottomPadding : 10),
          decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderLight))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 42, maxHeight: 100),
                  decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(22)),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    maxLength: 2000,
                    style: const TextStyle(
                        color: AppColors.text, fontSize: AppFontSize.sm),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: true,
                      counterText: '',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _sending
                        ? AppColors.teal.withValues(alpha: 0.35)
                        : AppColors.teal,
                  ),
                  child: Center(
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _bubble(Map<String, dynamic> msg, bool isMe) {
    final text = (msg['text'] ?? '').toString();
    final time = _formatTime(msg['createdAt']);
    final isPending = msg['_id']?.toString().startsWith('temp_') == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.teal : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text,
                style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: isMe ? Colors.white : AppColors.text,
                    height: 1.4)),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(time,
                  style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textMuted)),
              if (isMe && isPending) ...[
                const SizedBox(width: 4),
                Icon(Icons.access_time_rounded,
                    size: 10, color: Colors.white.withValues(alpha: 0.7)),
              ] else if (isMe) ...[
                const SizedBox(width: 4),
                Icon(Icons.done_rounded,
                    size: 10, color: Colors.white.withValues(alpha: 0.7)),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}
