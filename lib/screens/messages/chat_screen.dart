// lib/screens/messages/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String name;
  final String? participantId;
  final String? listingId;
  final String? listingTitle;
  final double? listingPrice;
  final String? listingCurrency;
  final String? listingImage;

  const ChatScreen({
    super.key,
    this.conversationId,
    required this.name,
    this.participantId,
    this.listingId,
    this.listingTitle,
    this.listingPrice,
    this.listingCurrency,
    this.listingImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService();
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
    if (_convoId != null) _load();
    else setState(() => _loading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_convoId == null) return;
    try {
      final res = await _api.get('/api/messages/conversations/$_convoId/messages');
      final body = res.data;
      List msgs;
      if (body['success'] == true && body['data'] is List) {
        msgs = body['data'];
      } else if (body['messages'] is List) {
        msgs = body['messages'];
      } else {
        msgs = [];
      }
      setState(() => _messages = List<Map<String, dynamic>>.from(msgs));
    } catch (e) {
      debugPrint('[Chat] Load error: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);

    try {
      if (_convoId != null) {
        // Send to existing conversation
        final res = await _api.post(
          '/api/messages/conversations/$_convoId/messages',
          data: {'content': text},
        );
        // Check if new convoId was returned
        final newId = res.data['data']?['conversationId'] ?? res.data['conversationId'];
        if (newId != null) _convoId ??= newId;
      } else if (widget.participantId != null) {
        // Create new conversation
        final res = await _api.post('/api/messages/conversations', data: {
          'participantId': widget.participantId,
          'content': text,
        });
        final newId = res.data['data']?['conversationId'] ??
            res.data['data']?['_id'] ??
            res.data['conversationId'];
        if (newId != null) _convoId = newId;
      }
      await _load();
    } catch (e) {
      debugPrint('[Chat] Send error: $e');
    }
    setState(() => _sending = false);
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(
        children: [
          // ── Listing Banner ──
          if (widget.listingTitle != null)
            GestureDetector(
              onTap: () {
                if (widget.listingId != null) {
                  // TODO: navigate to artwork detail
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                ),
                child: Row(
                  children: [
                    if (widget.listingImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(widget.listingImage!, width: 48, height: 48, fit: BoxFit.cover),
                      ),
                    if (widget.listingImage != null) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.listingTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.text),
                          ),
                          if (widget.listingPrice != null)
                            Text(
                              '${widget.listingCurrency ?? ''} ${widget.listingPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.teal),
                            ),
                        ],
                      ),
                    ),
                    const Text('›', style: TextStyle(fontSize: 20, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),

          // ── Messages ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Start a conversation with ${widget.name}',
                          style: const TextStyle(fontSize: AppFontSize.sm, color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          // Messages are newest-first when reversed
                          final msg = _messages[_messages.length - 1 - index];
                          final senderId = msg['senderId'] is Map
                              ? msg['senderId']['_id']
                              : msg['senderId'] ?? msg['sender'];
                          final isMe = senderId == currentUserId;
                          return _bubble(msg, isMe);
                        },
                      ),
          ),

          // ── Input Bar ──
          Container(
            padding: EdgeInsets.only(
              left: 12, right: 12, top: 10,
              bottom: bottomPadding > 0 ? bottomPadding : 10,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 42, maxHeight: 100),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      maxLength: 2000,
                      style: const TextStyle(color: AppColors.text, fontSize: AppFontSize.sm),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      color: _sending ? AppColors.teal.withValues(alpha: 0.35) : AppColors.teal,
                    ),
                    child: Center(
                      child: Text(
                        _sending ? '···' : '↑',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> msg, bool isMe) {
    final text = msg['text'] ?? msg['content'] ?? '';
    final time = _formatTime(msg['createdAt']);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: isMe ? Colors.white : AppColors.text,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
