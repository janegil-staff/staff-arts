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
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _searchResults = [];
  final Map<String, int> _unreadCounts = {};
  bool _loading = true;
  bool _searching = false;
  bool _searchLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _startSocketListener();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    SocketService().removeMessageListener('__conversations__');
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() {
        _searching = false;
        _searchResults = [];
      });
      return;
    }
    setState(() => _searching = true);
    _debounceSearch(q);
  }

  DateTime? _lastSearch;
  void _debounceSearch(String q) {
    _lastSearch = DateTime.now();
    final ts = _lastSearch;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_lastSearch == ts && mounted) _searchUsers(q);
    });
  }

  Future<void> _searchUsers(String q) async {
    setState(() => _searchLoading = true);
    try {
      final res = await _api.get(ApiConfig.users, params: {'search': q});
      final list = res.data['data'] as List? ?? [];
      final myId = context.read<AuthProvider>().user?.id ?? '';
      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(list)
              .where((u) => (u['_id'] ?? u['id']).toString() != myId)
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _searchLoading = false);
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
        if (senderId != myId) {
          _unreadCounts[convoId] = (_unreadCounts[convoId] ?? 0) + 1;
        }
        final idx = _conversations
            .indexWhere((c) => (c['_id'] ?? c['id'])?.toString() == convoId);
        if (idx > 0) {
          final convo = _conversations.removeAt(idx);
          convo['lastMessage'] = msg;
          convo['lastMessageAt'] = msg['createdAt'];
          _conversations.insert(0, convo);
        } else if (idx == 0) {
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
          for (final e in serverCounts.entries) {
            final live = _unreadCounts[e.key] ?? 0;
            _unreadCounts[e.key] = live > e.value ? live : e.value;
          }
          for (final c in convos) {
            final id = (c['_id'] ?? c['id'])?.toString() ?? '';
            if ((serverCounts[id] ?? 0) == 0 &&
                (_unreadCounts[id] ?? 0) <= 0) {
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

  Future<void> _openChatWithUser(Map<String, dynamic> user) async {
    final userId = (user['_id'] ?? user['id']).toString();
    final name = user['displayName'] ?? user['name'] ?? 'Unknown';
    _searchController.clear();
    setState(() {
      _searching = false;
      _searchResults = [];
    });
    try {
      final res = await _api
          .post(ApiConfig.conversations, data: {'participantId': userId});
      final convo = res.data['data'] as Map<String, dynamic>;
      final convoId = convo['_id']?.toString() ?? '';
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convoId,
            name: name,
            participantId: userId,
          ),
        ),
      ).then((_) => _load());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not open chat: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Map<String, dynamic>? _otherParticipant(List participants) {
    final myId = context.read<AuthProvider>().user?.id ?? '';
    for (final p in participants) {
      if (p is! Map) continue;
      final pid = (p['_id'] ?? p['id'] ?? '').toString();
      if (pid != myId) return Map<String, dynamic>.from(p);
    }
    return participants.isNotEmpty && participants.first is Map
        ? Map<String, dynamic>.from(participants.first)
        : null;
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
      body: Column(
        children: [
          // ── Search field ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                    color: AppColors.text, fontSize: AppFontSize.sm),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted, fontSize: AppFontSize.sm),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 20),
                  suffixIcon: _searching
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searching = false;
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: _searching
                ? _buildSearchResults()
                : _buildConversationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchLoading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.teal, strokeWidth: 2));
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No users found',
            style: TextStyle(
                fontSize: AppFontSize.sm, color: AppColors.textMuted)),
      );
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (_, i) => _buildUserRow(_searchResults[i]),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    final name = user['displayName'] ?? user['name'] ?? 'Unknown';
    final username = user['username'] as String?;
    final avatar = user['avatar'] as String?;
    final role = user['role'] as String? ?? '';

    return GestureDetector(
      onTap: () => _openChatWithUser(user),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            avatar != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatar,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _avatarFallback(name, 46),
                    ),
                  )
                : _avatarFallback(name, 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: AppFontSize.md,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text)),
                  if (username != null)
                    Text('@$username',
                        style: const TextStyle(
                            fontSize: AppFontSize.xs,
                            color: AppColors.textMuted)),
                ],
              ),
            ),
            if (role.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tealBg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  role[0].toUpperCase() + role.substring(1),
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.teal));
    }
    if (_conversations.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Text('💬', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('No conversations yet',
              style: TextStyle(
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w300,
                  color: AppColors.text)),
          SizedBox(height: 6),
          Text('Search for a user to start a conversation',
              style: TextStyle(
                  fontSize: AppFontSize.sm, color: AppColors.textMuted)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.teal,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, i) => _buildRow(_conversations[i]),
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
    final convoId = convo['_id']?.toString() ?? '';
    final unread = _unreadCounts[convoId] ?? 0;

    return GestureDetector(
      onTap: () {
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
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: AppColors.borderLight))),
        child: Row(children: [
          avatar != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatar,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _avatarFallback(name, 50),
                  ),
                )
              : _avatarFallback(name, 50),
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
                        color: unread > 0
                            ? AppColors.teal
                            : AppColors.textMuted,
                        fontWeight: unread > 0
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
                          color: unread > 0
                              ? AppColors.text
                              : AppColors.textMuted,
                          fontWeight: unread > 0
                              ? FontWeight.w500
                              : FontWeight.w400)),
                ),
                if (unread > 0) ...[
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
                        '$unread',
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

  Widget _avatarFallback(String name, double size) => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          shape: BoxShape.circle, color: AppColors.teal),
      child: Center(
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w700))));
}