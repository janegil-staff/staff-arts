// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/artwork_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artwork_card.dart';
import '../../widgets/section_header.dart';
import '../artwork/artwork_detail_screen.dart';
import '../shows/event_detail_screen.dart';
import '../shows/exhibition_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _upcoming = [];

  @override
  void initState() {
    super.initState();
    _fetchUpcoming();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArtworkProvider>().fetchArtworks(refresh: true);
    });
  }

  Future<void> _fetchUpcoming() async {
    final items = <Map<String, dynamic>>[];
    final df = DateFormat('MMM d');

    // Fetch events
    try {
      final res = await _api
          .get(ApiConfig.events, params: {'limit': '10', 'sort': 'date'});
      final body = res.data as Map<String, dynamic>;
      final list = (body['data'] as List<dynamic>? ?? []);
      for (final j in list) {
        if (j is! Map) continue;
        final m = Map<String, dynamic>.from(j);
        final d = DateTime.tryParse(m['date']?.toString() ?? '');
        final cover = m['coverImage'];
        m['_imageUrl'] =
            (cover is Map) ? (cover['url']?.toString() ?? '') : '';
        m['_date'] = d ?? DateTime.now();
        m['_kind'] = 'event';
        m['_badge'] = _eventLabel(m['type']?.toString() ?? 'other');
        items.add(m);
      }
    } catch (e) {
      debugPrint('Events error: $e');
    }

    // Fetch exhibitions
    try {
      final res =
          await _api.get(ApiConfig.exhibitions, params: {'limit': '10'});
      final body = res.data as Map<String, dynamic>;
      final list = (body['data'] as List<dynamic>? ?? []);
      for (final j in list) {
        if (j is! Map) continue;
        final m = Map<String, dynamic>.from(j);
        final d = DateTime.tryParse(m['startDate']?.toString() ?? '');
        final cover = m['coverImage'];
        m['_imageUrl'] = (cover is Map)
            ? (cover['url']?.toString() ?? '')
            : (cover is String ? cover : '');
        m['_date'] = d ?? DateTime.now();
        m['_kind'] = 'exhibition';
        m['_badge'] = 'Exhibition';
        items.add(m);
      }
    } catch (e) {
      debugPrint('Exhibitions error: $e');
    }

    // Fetch music/tracks
    try {
      final res = await _api.get(ApiConfig.tracks, params: {'limit': '10'});
      final body = res.data as Map<String, dynamic>;
      final list = (body['tracks'] ??
          body['data']?['tracks'] ??
          body['data'] ??
          []) as List<dynamic>;
      for (final j in list) {
        if (j is! Map) continue;
        final m = Map<String, dynamic>.from(j);
        final coverImage = m['coverImage']?.toString() ?? '';
        m['_imageUrl'] = coverImage;
        m['_date'] = DateTime.now();
        m['_kind'] = 'music';
        m['_badge'] = m['genre']?.toString().isNotEmpty == true
            ? m['genre'].toString()
            : 'Music';
        items.add(m);
      }
    } catch (e) {
      debugPrint('Music error: $e');
    }

    // Sort by date descending (newest first), take 6
    // Keep only future items, sort ascending (nearest first), take 3
    final now = DateTime.now();
    final future = items
        .where((i) => (i['_date'] as DateTime).isAfter(now))
        .toList()
      ..sort((a, b) =>
          (a['_date'] as DateTime).compareTo(b['_date'] as DateTime));

    if (mounted) {
      setState(() => _upcoming = future.take(3).toList());
    }
  }

  String _eventLabel(String type) {
    const m = {
      'opening': 'Opening',
      'workshop': 'Workshop',
      'talk': 'Talk',
      'fair': 'Art Fair',
      'concert': 'Concert',
      'dj_set': 'DJ Set',
      'live_performance': 'Live',
      'open_mic': 'Open Mic',
      'festival': 'Festival',
      'album_release': 'Release',
    };
    return m[type] ?? 'Event';
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<ArtworkProvider>().fetchArtworks(refresh: true),
      _fetchUpcoming(),
    ]);
  }

  void _onUpcomingTap(Map<String, dynamic> item) {
    final kind = item['_kind'];
    final id = item['_id']?.toString() ?? '';
    if (id.isEmpty) return;

    if (kind == 'event') {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(id: id),
          ));
    } else if (kind == 'exhibition') {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExhibitionDetailScreen(id: id),
          ));
    }
    // music taps can be wired up later
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<ArtworkProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final firstName = user?.name?.split(' ').first ?? 'there';

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.teal,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ── Greeting ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: AppFontSize.xxl,
                    fontWeight: FontWeight.w300,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),

          // ── Upcoming (events, exhibitions, music) ──
          if (_upcoming.isNotEmpty) ...[
            const SectionHeader(label: 'Shows & Music'),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: _upcoming.map((item) => _buildShowRow(item)).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ── Just Added (6 newest artworks) ──
          if (provider.artworks.isNotEmpty) ...[
            const SectionHeader(label: 'Just Added'),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildRecentGrid(provider, screenWidth),
            ),
          ],

          // ── Empty state ──
          if (provider.artworks.isEmpty &&
              _upcoming.isEmpty &&
              !provider.loading) ...[
            const SizedBox(height: 60),
            const Center(
              child: Column(
                children: [
                  Text('\u{1F3A8}', style: TextStyle(fontSize: 48)),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Nothing here yet',
                    style: TextStyle(
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'New artworks and events will appear\nhere as artists add them',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Loading ──
          if (provider.loading && provider.artworks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShowRow(Map<String, dynamic> item) {
    final kind = item['_kind'] as String;
    final imageUrl = item['_imageUrl'] as String? ?? '';
    final date = item['_date'] as DateTime;
    final badge = item['_badge'] as String? ?? '';
    final title = item['title']?.toString() ?? '';
    final location = item['location']?.toString() ?? '';
    final isFree = item['isFree'] == true;
    final hasImage = imageUrl.isNotEmpty;

    final Color color;
    final Color bg;
    final IconData kindIcon;
    final String dateStr;

    if (kind == 'exhibition') {
      color = const Color(0xFF60a5fa);
      bg = const Color(0xFF1e2d4a);
      kindIcon = Icons.museum_outlined;
      dateStr = DateFormat('MMM d').format(date);
    } else if (kind == 'music') {
      color = const Color(0xFFc084fc);
      bg = const Color(0xFF2d1b4e);
      kindIcon = Icons.music_note;
      dateStr = '';
    } else {
      color = const Color(0xFF2dd4a0);
      bg = const Color(0xFF0d3b2e);
      kindIcon = Icons.event;
      dateStr = DateFormat('MMM d').format(date);
    }

    final details = [
      badge,
      if (dateStr.isNotEmpty) dateStr,
      if (location.isNotEmpty) location,
    ].join('  ·  ');

    return GestureDetector(
      onTap: () => _onUpcomingTap(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(
                  imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _iconThumb(bg, kindIcon, color),
                ),
              )
            else
              _iconThumb(bg, kindIcon, color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppFontSize.xs,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isFree)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.teal),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Text(
                  'Free',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: Text(
                '›',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppFontSize.sm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconThumb(Color bg, IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Center(child: Icon(icon, size: 20, color: color)),
    );
  }

  Widget _buildRecentGrid(ArtworkProvider provider, double screenWidth) {
    final colWidth = (screenWidth - AppSpacing.lg * 2 - AppSpacing.xs * 2) / 3;
    final items = provider.artworks.take(6).toList();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.md,
      children: items.map((artwork) {
        return ArtworkCard(
          artwork: artwork,
          width: colWidth,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArtworkDetailScreen(artwork: artwork),
            ),
          ),
        );
      }).toList(),
    );
  }
}
