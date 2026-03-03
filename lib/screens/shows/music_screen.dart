// lib/screens/shows/music_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final _api = ApiService();
  List<dynamic> _tracks = [];
  bool _loading = true;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get(ApiConfig.tracks);
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _tracks = (data['tracks'] ??
            data['data']?['tracks'] ??
            data['data'] ??
            []) as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Music load error: $e');
      setState(() => _loading = false);
    }
  }

  void _navigateToProfile(dynamic profileObj) {
    if (profileObj == null) return;
    final auth = context.read<AuthProvider>();
    final currentUser = auth.user;

    if (profileObj is Map<String, dynamic>) {
      final profileId = (profileObj['_id'] ?? '').toString();
      final myId = (currentUser?.id ?? '').toString();
      if (myId.isNotEmpty && profileId == myId) {
        return;
      }
    }
  }

  String _formatDuration(dynamic seconds) {
    final s = (seconds is int) ? seconds : int.tryParse('$seconds') ?? 0;
    final mins = s ~/ 60;
    final secs = s % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : _tracks.isEmpty
              ? _buildEmpty()
              : _buildContent(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(Icons.music_note_rounded,
                size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('No tracks yet',
              style: TextStyle(
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.xs),
          const Text('Music will appear here',
              style: TextStyle(
                  fontSize: AppFontSize.sm, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Group by album if available
    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: AppColors.bg,
          title: const Text('Music',
              style: TextStyle(
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 1)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Text('${_tracks.length} tracks',
                  style: const TextStyle(
                      fontSize: AppFontSize.sm, color: AppColors.textMuted)),
            ),
          ],
        ),

        // Featured track (first one with cover image)
        ..._buildFeaturedTrack(),

        // Track list header
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
            child: Text('ALL TRACKS',
                style: TextStyle(
                    fontSize: AppFontSize.xxs,
                    letterSpacing: 2.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600)),
          ),
        ),

        // Track list
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTrackTile(_tracks[index], index),
              childCount: _tracks.length,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeaturedTrack() {
    final featured = _tracks.firstWhere(
      (t) =>
          t is Map<String, dynamic> &&
          t['coverImage'] != null &&
          t['coverImage'].toString().isNotEmpty,
      orElse: () => null,
    );
    if (featured == null) return [];

    final track = featured as Map<String, dynamic>;
    final isPlaying = _playingId == (track['_id'] ?? track['id']);
    final artist = track['artist'];
    final artistName = artist is Map<String, dynamic>
        ? (artist['displayName'] ?? artist['name'] ?? '')
        : '';

    return [
      SliverToBoxAdapter(
        child: GestureDetector(
          onTap: () {
            setState(() => _playingId = track['_id'] ?? track['id']);
          },
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              image: DecorationImage(
                image: NetworkImage(track['coverImage']),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (track['genre'] != null &&
                      track['genre'].toString().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        track['genre'].toString().toUpperCase(),
                        style: const TextStyle(
                            fontSize: AppFontSize.xxs,
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1),
                      ),
                    ),
                  Text(track['title'] ?? '',
                      style: const TextStyle(
                          fontSize: AppFontSize.xxl,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 0.5)),
                  if (artistName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(artistName,
                        style: TextStyle(
                            fontSize: AppFontSize.md,
                            color: Colors.white.withValues(alpha: 0.7))),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? AppColors.teal
                              : Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color:
                              isPlaying ? AppColors.textInverse : Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      if (track['duration'] != null)
                        Text(_formatDuration(track['duration']),
                            style: TextStyle(
                                fontSize: AppFontSize.sm,
                                color: Colors.white.withValues(alpha: 0.6))),
                      const Spacer(),
                      Text('${track['plays'] ?? 0} plays',
                          style: TextStyle(
                              fontSize: AppFontSize.sm,
                              color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildTrackTile(dynamic item, int index) {
    if (item is! Map<String, dynamic>) return const SizedBox.shrink();
    final track = item;
    final trackId = track['_id'] ?? track['id'] ?? '';
    final isPlaying = _playingId == trackId;
    final artist = track['artist'];
    final artistName = artist is Map<String, dynamic>
        ? (artist['displayName'] ?? artist['name'] ?? '')
        : '';
    final coverImage = track['coverImage']?.toString();
    final hasCover = coverImage != null && coverImage.isNotEmpty;

    return GestureDetector(
      onTap: () {
        setState(() => _playingId = trackId);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.tealBg : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: isPlaying
                  ? AppColors.teal.withValues(alpha: 0.3)
                  : AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Track number or cover
            if (hasCover)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(coverImage!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _coverPlaceholder()),
              )
            else
              _coverPlaceholder(),

            const SizedBox(width: AppSpacing.md),

            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track['title'] ?? '',
                    style: TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w500,
                      color: isPlaying ? AppColors.teal : AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (artistName.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () => _navigateToProfile(artist),
                          child: Text(artistName,
                              style: const TextStyle(
                                  fontSize: AppFontSize.sm,
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                      if (artistName.isNotEmpty &&
                          track['album'] != null &&
                          track['album'].toString().isNotEmpty)
                        const Text(' · ',
                            style: TextStyle(
                                fontSize: AppFontSize.sm,
                                color: AppColors.textMuted)),
                      if (track['album'] != null &&
                          track['album'].toString().isNotEmpty)
                        Flexible(
                          child: Text(track['album'],
                              style: const TextStyle(
                                  fontSize: AppFontSize.sm,
                                  color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Duration & play icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (track['duration'] != null)
                  Text(_formatDuration(track['duration']),
                      style: const TextStyle(
                          fontSize: AppFontSize.xs,
                          color: AppColors.textMuted,
                          fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Icon(
                  isPlaying
                      ? Icons.equalizer_rounded
                      : Icons.play_arrow_rounded,
                  size: 18,
                  color: isPlaying ? AppColors.teal : AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Icon(Icons.music_note_rounded,
          size: 22, color: AppColors.textMuted),
    );
  }
}
