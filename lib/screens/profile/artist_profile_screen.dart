// lib/screens/profile/artist_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/artwork_model.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artwork_card.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../artwork/artwork_detail_screen.dart';
import '../messages/chat_screen.dart';

class ArtistProfileScreen extends StatefulWidget {
  final String? userId;
  final String? username;

  const ArtistProfileScreen({super.key, this.userId, this.username});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> {
  final _api = ApiService();
  UserModel? _artist;
  List<ArtworkModel> _artworks = [];
  bool _loading = true;
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final path = widget.username != null
          ? ApiConfig.userByUsername(widget.username!)
          : ApiConfig.user(widget.userId ?? '');
      final res = await _api.get(path);
      final data = res.data['data'] ?? res.data;
      setState(() {
        _artist = UserModel.fromJson(data);
        _isFollowing = data['isFollowing'] == true;
      });

      final artRes = await _api.get(ApiConfig.artworks, params: {
        'artist': _artist!.id,
        'status': 'all',
        'limit': 20,
      });
      final artList =
          (artRes.data['data'] ?? artRes.data['artworks'] ?? []) as List;
      setState(() {
        _artworks =
            artList.map<ArtworkModel>((j) => ArtworkModel.fromJson(j)).toList();
      });
    } catch (e) {
      debugPrint('Artist profile error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleFollow() async {
    if (_artist == null || _followLoading) return;
    setState(() => _followLoading = true);
    try {
      final res = await _api.post(ApiConfig.userFollow(_artist!.id));
      final following = res.data['data']['following'] == true;
      setState(() {
        _isFollowing = following;
        _artist = _artist!.copyWith(
          followerCount: following
              ? _artist!.followerCount + 1
              : _artist!.followerCount - 1,
        );
      });
    } catch (e) {
      debugPrint('Follow error: $e');
    }
    if (mounted) setState(() => _followLoading = false);
  }

  Future<void> _openChat() async {
    if (_artist == null) return;
    try {
      final res = await _api.post(ApiConfig.conversations, data: {
        'participantId': _artist!.id,
      });
      final convoData = res.data['data'] as Map<String, dynamic>;
      final convoId = (convoData['_id'] ?? convoData['id']).toString();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convoId,
            participantId: _artist!.id,
            name: _artist!.displayLabel,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Open chat error: $e');
    }
  }

  void _requireLogin(VoidCallback action) {
    final isLoggedIn = context.read<AuthProvider>().isAuthenticated;
    if (!isLoggedIn) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    action();
  }

  bool get _isOwnProfile {
    final myId = context.read<AuthProvider>().user?.id ?? '';
    return myId.isNotEmpty && myId == _artist?.id;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colWidth = (screenWidth - AppSpacing.lg * 2 - AppSpacing.sm) / 2;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }

    if (_artist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Artist not found',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final a = _artist!;

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ── Cover + Avatar ───────────────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 160,
                width: double.infinity,
                color: AppColors.surfaceDim,
                child: a.coverImage != null
                    ? CachedNetworkImage(
                        imageUrl: a.coverImage!, fit: BoxFit.cover)
                    : null,
              ),
              Positioned(
                bottom: -40,
                left: AppSpacing.lg,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.bg, width: 3),
                  ),
                  child: a.avatar != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                              imageUrl: a.avatar!, fit: BoxFit.cover))
                      : Center(
                          child: Text(
                            (a.displayLabel).isNotEmpty
                                ? a.displayLabel[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal),
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // ── Info ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + verified
                Row(children: [
                  Expanded(
                    child: Text(
                      a.displayLabel,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text),
                    ),
                  ),
                  if (a.verified)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child:
                          Icon(Icons.verified, color: AppColors.teal, size: 20),
                    ),
                ]),

                // Username
                if (a.username != null) ...[
                  const SizedBox(height: 2),
                  Text('@${a.username}',
                      style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textMuted)),
                ],

                // Role badge
                if (a.role != 'collector') ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tealBg,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      a.role[0].toUpperCase() + a.role.substring(1),
                      style: const TextStyle(
                          fontSize: AppFontSize.xs,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],

                // Bio
                if (a.bio != null && a.bio!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(a.bio!,
                      style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textSecondary,
                          height: 1.5)),
                ],

                // Location
                if (a.location != null && a.location!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(a.location!,
                        style: const TextStyle(
                            fontSize: AppFontSize.xs,
                            color: AppColors.textMuted)),
                  ]),
                ],

                // Mediums
                if (a.mediums.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    children: a.mediums
                        .map((m) => Chip(
                              label: Text(m,
                                  style: const TextStyle(
                                      fontSize: AppFontSize.xs)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Stats
                Row(children: [
                  _stat('${a.followerCount}', 'Followers'),
                  const SizedBox(width: AppSpacing.xl),
                  _stat('${a.followingCount}', 'Following'),
                  const SizedBox(width: AppSpacing.xl),
                  _stat('${a.artworkCount}', 'Works'),
                ]),

                const SizedBox(height: AppSpacing.md),

                // Buttons — hide on own profile
                if (!_isOwnProfile)
                  Row(children: [
                    Expanded(
                      child: _followLoading
                          ? OutlinedButton(
                              onPressed: null,
                              child: const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.teal),
                              ),
                            )
                          : _isFollowing
                              ? OutlinedButton(
                                  onPressed: () => _requireLogin(_toggleFollow),
                                  child: const Text('Following'),
                                )
                              : ElevatedButton(
                                  onPressed: () => _requireLogin(_toggleFollow),
                                  child: const Text('Follow'),
                                ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _requireLogin(_openChat),
                        child: const Text('Message'),
                      ),
                    ),
                  ]),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Artworks grid ────────────────────────────────────────────────
          if (_artworks.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'ARTWORKS',
                style: TextStyle(
                    fontSize: AppFontSize.xxs,
                    letterSpacing: 2,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.md,
                children: _artworks.map((artwork) {
                  return ArtworkCard(
                    artwork: artwork,
                    width: colWidth,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ArtworkDetailScreen(artwork: artwork)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else if (!_loading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.xl),
                child: Text(
                  'No artworks yet',
                  style: TextStyle(
                      fontSize: AppFontSize.sm, color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String count, String label) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
        Text(label,
            style: const TextStyle(
                fontSize: AppFontSize.xs, color: AppColors.textMuted)),
      ],
    );
  }
}
