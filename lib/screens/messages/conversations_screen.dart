// lib/screens/messages/conversations_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/api/messages/conversations');
      final body = res.data;
      if (body['success'] == true && body['data'] is List) {
        setState(() => _conversations = List<Map<String, dynamic>>.from(body['data']));
      }
    } catch (e) {
      debugPrint('[Conversations] Fetch error: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    await _load();
    setState(() => _refreshing = false);
  }

  Map<String, dynamic>? _getOtherParticipant(List? participants) {
    if (participants == null || participants.isEmpty) return null;
    final user = context.read<AuthProvider>().user;
    final myId = user?.id ?? '';
    return participants.firstWhere(
      (p) {
        final pid = p is Map ? (p['_id'] ?? '') : p;
        return pid.toString() != myId;
      },
      orElse: () => participants.first,
    );
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(d).inSeconds;
      if (diff < 60) return 'now';
      if (diff < 3600) return '${diff ~/ 60}m';
      if (diff < 86400) return '${diff ~/ 3600}h';
      if (diff < 604800) return '${diff ~/ 86400}d';
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _loading && _conversations.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _conversations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('💬', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No conversations yet', style: TextStyle(fontSize: AppFontSize.lg, fontWeight: FontWeight.w600, color: AppColors.text)),
                      SizedBox(height: 6),
                      Text('Message an artist to start a conversation', style: TextStyle(fontSize: AppFontSize.sm, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppColors.teal,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) => _buildRow(_conversations[index]),
                  ),
                ),
    );
  }

  Widget _buildRow(Map<String, dynamic> convo) {
    final participants = convo['participants'] as List?;
    final other = _getOtherParticipant(participants);
    final otherMap = (other is Map<String, dynamic>) ? other : <String, dynamic>{};
    final name = otherMap['displayName'] ?? otherMap['name'] ?? 'Unknown';
    final avatar = otherMap['avatar'] as String?;
    final otherId = otherMap['_id'] as String?;
    final lastMsg = convo['lastMessage'] as Map<String, dynamic>?;
    final preview = lastMsg?['content'] ?? lastMsg?['text'] ?? 'No messages yet';
    final timeStr = _timeAgo(
      lastMsg?['createdAt'] ?? convo['lastMessageAt'] ?? convo['updatedAt'],
    );
    final unread = convo['unreadCount'] ?? 0;
    final hasUnread = unread > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convo['_id'],
              name: name,
              participantId: otherId,
            ),
          ),
        ).then((_) => _load()); // Refresh on return
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: hasUnread ? AppColors.surface : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            // Avatar
            avatar != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatar,
                      width: 50, height: 50, fit: BoxFit.cover,
                      placeholder: (_, __) => _avatarFallback(name),
                      errorWidget: (_, __, ___) => _avatarFallback(name),
                    ),
                  )
                : _avatarFallback(name),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                children: [
                  // Top row: name + time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppFontSize.md,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread ? AppColors.teal : AppColors.textMuted,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Bottom row: preview + badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppFontSize.sm,
                            color: hasUnread ? AppColors.text : AppColors.textMuted,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 10),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      width: 50, height: 50,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: AppFontSize.lg, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}