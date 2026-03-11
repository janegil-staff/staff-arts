// lib/screens/profile/artist_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/artwork_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artwork_card.dart';
import '../artwork/artwork_detail_screen.dart';

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
      });

      final artRes = await _api.get(ApiConfig.artworks, params: {
        'artist': _artist!.id,
        'status': 'all',
        'limit': 20,
      });
      final artList = (artRes.data['data'] ?? artRes.data['artworks'] ?? [])
          as List<dynamic>;
      setState(() {
        _artworks =
            artList.map<ArtworkModel>((j) => ArtworkModel.fromJson(j)).toList();
      });
    } catch (e) {
      debugPrint('Artist profile error: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleFollow() async {
    if (_artist == null) return;
    try {
      await _api.post(ApiConfig.userFollow(_artist!.id));
      setState(() => _isFollowing = !_isFollowing);
    } catch (_) {}
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
          // ── Cover + Avatar ──
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
                            (a.displayName ?? a.name ?? '?')[0].toUpperCase(),
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

          // ── Info ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(a.displayLabel,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                  ),
                  if (a.verified)
                    const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.verified,
                            color: AppColors.teal, size: 20)),
                ]),
                if (a.username != null)
                  Text('@${a.username}',
                      style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textMuted)),
                if (a.bio != null && a.bio!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(a.bio!,
                      style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textSecondary,
                          height: 1.5)),
                ],
                if (a.location != null && a.location!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('📍 ${a.location}',
                      style: const TextStyle(
                          fontSize: AppFontSize.xs,
                          color: AppColors.textMuted)),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  _stat('${a.followerCount}', 'Followers'),
                  const SizedBox(width: AppSpacing.xl),
                  _stat('${a.followingCount}', 'Following'),
                  const SizedBox(width: AppSpacing.xl),
                  _stat('${a.artworkCount}', 'Works'),
                ]),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  Expanded(
                    child: _isFollowing
                        ? OutlinedButton(
                            onPressed: _toggleFollow,
                            child: const Text('Following'))
                        : ElevatedButton(
                            onPressed: _toggleFollow,
                            child: const Text('Follow')),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                      onPressed: () {}, child: const Text('Message')),
                ]),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Artworks Grid ──
          if (_artworks.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('ARTWORKS',
                  style: TextStyle(
                      fontSize: AppFontSize.xxs,
                      letterSpacing: 2,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
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
                                ArtworkDetailScreen(artwork: artwork))),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String count, String label) {
    return Column(children: [
      Text(count,
          style: const TextStyle(
              fontSize: AppFontSize.lg,
              fontWeight: FontWeight.w600,
              color: AppColors.text)),
      Text(label,
          style: const TextStyle(
              fontSize: AppFontSize.xs, color: AppColors.textMuted)),
    ]);
  }
}
