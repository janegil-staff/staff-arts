// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import '../messages/conversations_screen.dart';
import '../artwork/saved_artworks_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnread();
    _startMessageListener();
    _startFollowListener();
  }

  @override
  void dispose() {
    SocketService().removeMessageListener('__profile__');
    SocketService().removeFollowListener();
    super.dispose();
  }

  Future<void> _fetchUnread() async {
    try {
      final res = await _api.get(ApiConfig.conversationsUnread);
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] is Map) {
        final counts = body['data'] as Map;
        final total =
            counts.values.fold<int>(0, (sum, v) => sum + (v as num).toInt());
        if (mounted) setState(() => _unreadCount = total);
      }
    } catch (_) {}
  }

  void _startMessageListener() async {
    final socket = SocketService();
    await socket.connect();
    socket.addMessageListener('__profile__', (msg) {
      if (!mounted) return;
      final myId = context.read<AuthProvider>().user?.id ?? '';
      final sender = msg['sender'];
      final senderId = sender is Map
          ? (sender['_id'] ?? sender['id'] ?? '').toString()
          : (sender ?? '').toString();
      if (senderId != myId) setState(() => _unreadCount++);
    });
  }

  void _startFollowListener() async {
    final socket = SocketService();
    await socket.connect();
    if (!mounted) return;
    final myId = context.read<AuthProvider>().user?.id ?? '';
    if (myId.isEmpty) return;
    socket.joinUserRoom(myId);
    socket.onFollowUpdate((data) {
      if (!mounted) return;
      final count = data['followerCount'] as int? ?? 0;
      context.read<AuthProvider>().updateFollowerCount(count);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // ── Avatar & Info ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          child: Column(
            children: [
              if (user.avatar != null && user.avatar!.isNotEmpty)
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderLight, width: 2),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(user.avatar!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.borderLight, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      (user.displayName ?? user.name ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                user.displayLabel,
                style: const TextStyle(
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.w300,
                  color: AppColors.text,
                ),
              ),
              if (user.username != null) ...[
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  user.role[0].toUpperCase() + user.role.substring(1),
                  style: const TextStyle(
                    fontSize: AppFontSize.xxs,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  user.bio!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              if (user.location != null && user.location!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '📍 ${user.location}',
                  style: const TextStyle(
                    fontSize: AppFontSize.xs,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Stats Bar ────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              _statItem('Followers', user.followerCount, showDivider: true),
              _statItem('Following', user.followingCount, showDivider: true),
              _statItem('Works', user.artworkCount, showDivider: false),
            ],
          ),
        ),

        // ── Edit Profile ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: OutlinedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true)
                .push(MaterialPageRoute(
                    builder: (_) => const EditProfileScreen()))
                .then((_) => context.read<AuthProvider>().refreshUser()),
            child: const Text(
              'Edit Profile',
              style: TextStyle(fontSize: AppFontSize.md),
            ),
          ),
        ),

        // ── Menu Items ───────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              _menuItem(context, '🎨', 'My Artworks', null, () {}),
              _divider(),
              _menuItem(context, '🔖', 'Saved Artworks', null, () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                      builder: (_) => const SavedArtworksScreen()),
                );
              }),
              _divider(),
              _menuItem(context, '📦', 'Orders', null, () {}),
              _divider(),
              _menuItem(context, '✏️', 'Commissions', null, () {}),
              _divider(),
              _menuItem(
                context,
                '💬',
                'Messages',
                _unreadCount > 0 ? _unreadCount : null,
                () {
                  setState(() => _unreadCount = 0);
                  Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute(
                          builder: (_) => const ConversationsScreen()))
                      .then((_) => _fetchUnread());
                },
              ),
              _divider(),
              _menuItem(context, '⚙️', 'Settings', null, () {}),
            ],
          ),
        ),

        // ── Sign Out ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: TextButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: AppFontSize.md,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, int count, {required bool showDivider}) {
    return Expanded(
      child: Container(
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.borderLight)))
            : null,
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  fontSize: AppFontSize.xs, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, String icon, String label, int? badge,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: AppFontSize.md, color: AppColors.text)),
            ),
            if (badge != null && badge > 0) ...[
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
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Text('›',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 0, indent: AppSpacing.lg, endIndent: AppSpacing.lg);
}
