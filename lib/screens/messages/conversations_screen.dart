// lib/screens/messages/conversations_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import '../../services/socket_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _conversations = [];
  final Map<String, int> _unreadCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _startSocketListener();
  }

  @override
  void dispose() {
    SocketService().removeMessageListener('__conversations__');
    super.dispose();
  }

  void _startSocketListener() async {
    final socket = SocketService();
    await socket.connect();
    socket.addMessageListener('__conversations__', (msg) {
      if (!mounted) return;
      final myId = context.read<AuthProvider>().user?.id ?? '';
      final sender = msg['sender'];
      final senderId = sender is Map
          ? (sender['_id'] ?? sender['id'] ?? '').toString()
          : (sender ?? '').toString();
      final convoId = (msg['conversation'] ?? '').toString();
      if (convoId.isEmpty) return;

      setState(() {
        // Increment unread for messages from others
        if (senderId != myId) {
          _unreadCounts[convoId] = (_unreadCounts[convoId] ?? 0) + 1;
        }
        // Move conversation to top of list
        final idx = _conversations
            .indexWhere((c) => (c['_id'] ?? c['id'])?.toString() == convoId);
        if (idx > 0) {
          final convo = _conversations.removeAt(idx);
          // Update lastMessage preview
          convo['lastMessage'] = msg;
          convo['lastMessageAt'] = msg['createdAt'];
          _conversations.insert(0, convo);
        } else if (idx == 0) {
          // Already on top, just update preview
          _conversations[0]['lastMessage'] = msg;
          _conversations[0]['lastMessageAt'] = msg['createdAt'];
        }
      });
    });
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.get(ApiConfig.conversations),
        _api.get(ApiConfig.conversationsUnread),
      ]);

      final convosBody = results[0].data as Map<String, dynamic>;
      final unreadBody = results[1].data as Map<String, dynamic>;

      if (convosBody['success'] == true && convosBody['data'] is List) {
        final convos = List<Map<String, dynamic>>.from(convosBody['data']);
        final serverCounts =
            unreadBody['success'] == true && unreadBody['data'] is Map
                ? Map<String, int>.from((unreadBody['data'] as Map)
                    .map((k, v) => MapEntry(k.toString(), (v as num).toInt())))
                : <String, int>{};

        setState(() {
          _conversations = convos;
          // Merge server counts with live socket counts (take the higher value)
          for (final e in serverCounts.entries) {
            final live = _unreadCounts[e.key] ?? 0;
            _unreadCounts[e.key] = live > e.value ? live : e.value;
          }
          // Clear counts for conversations the server says are read
          for (final c in convos) {
            final id = (c['_id'] ?? c['id'])?.toString() ?? '';
            if ((serverCounts[id] ?? 0) == 0 && (_unreadCounts[id] ?? 0) <= 0) {
              _unreadCounts.remove(id);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Conversations fetch error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic>? _otherParticipant(List participants) {
    final myId = context.read<AuthProvider>().user?.id ?? '';
    return participants.firstWhere(
      (p) => (p is Map ? (p['_id'] ?? p['id'] ?? '') : p).toString() != myId,
      orElse: () => participants.isNotEmpty ? participants.first : null,
    );
  }

  String _timeAgo(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final d = DateTime.parse(dateVal.toString());
      final diff = DateTime.now().difference(d);
      if (diff.inSeconds < 60) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.w300)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : _conversations.isEmpty
              ? Center(
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: const [
                    Text('💬', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('No conversations yet',
                        style: TextStyle(
                            fontSize: AppFontSize.lg,
                            fontWeight: FontWeight.w300,
                            color: AppColors.text)),
                    SizedBox(height: 6),
                    Text('Message an artist to start a conversation',
                        style: TextStyle(
                            fontSize: AppFontSize.sm,
                            color: AppColors.textMuted)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.teal,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, i) => _buildRow(_conversations[i]),
                  ),
                ),
    );
  }

  Widget _buildRow(Map<String, dynamic> convo) {
    final participants = (convo['participants'] as List? ?? []);
    final other = _otherParticipant(participants);
    final otherMap =
        other is Map<String, dynamic> ? other : <String, dynamic>{};
    final name = otherMap['displayName'] ?? otherMap['name'] ?? 'Unknown';
    final avatar = otherMap['avatar'] as String?;
    final otherId = (otherMap['_id'] ?? otherMap['id'] ?? '').toString();
    final lastMsg = convo['lastMessage'] as Map<String, dynamic>?;
    final preview = lastMsg?['text'] ?? 'No messages yet';
    final timeStr = _timeAgo(lastMsg?['createdAt'] ?? convo['lastMessageAt']);

    return GestureDetector(
      onTap: () {
        final convoId = convo['_id']?.toString() ?? '';
        setState(() => _unreadCounts.remove(convoId));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convoId,
              name: name,
              participantId: otherId,
            ),
          ),
        ).then((_) => _load());
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderLight))),
        child: Row(children: [
          // Avatar
          avatar != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatar,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _avatarFallback(name),
                  ),
                )
              : _avatarFallback(name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: AppFontSize.md,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text))),
                Text(timeStr,
                    style: TextStyle(
                        fontSize: 12,
                        color: (_unreadCounts[convo['_id']?.toString() ?? ''] ??
                                    0) >
                                0
                            ? AppColors.teal
                            : AppColors.textMuted,
                        fontWeight:
                            (_unreadCounts[convo['_id']?.toString() ?? ''] ??
                                        0) >
                                    0
                                ? FontWeight.w600
                                : FontWeight.w400)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: Text(preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: AppFontSize.sm,
                          color:
                              (_unreadCounts[convo['_id']?.toString() ?? ''] ??
                                          0) >
                                      0
                                  ? AppColors.text
                                  : AppColors.textMuted,
                          fontWeight:
                              (_unreadCounts[convo['_id']?.toString() ?? ''] ??
                                          0) >
                                      0
                                  ? FontWeight.w500
                                  : FontWeight.w400)),
                ),
                if ((_unreadCounts[convo['_id']?.toString() ?? ''] ?? 0) >
                    0) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        '${_unreadCounts[convo['_id']?.toString() ?? '']}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _avatarFallback(String name) => Container(
      width: 50,
      height: 50,
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal),
      child: Center(
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w700))));
}
