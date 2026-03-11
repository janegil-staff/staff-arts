// lib/screens/shows/shows_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/shows_service.dart';
import '../../screens/auth/login_screen.dart';
import 'event_detail_screen.dart';
import 'exhibition_detail_screen.dart';
import 'events_screen.dart';
import 'exhibitions_screen.dart';
import 'music_screen.dart';
import 'create_show_screen.dart';

// ── Type configs ──

class _TypeConfig {
  final String icon;
  final String label;
  final Color color;
  final Color bg;
  const _TypeConfig(
      {required this.icon,
      required this.label,
      required this.color,
      required this.bg});
}

const _typeConfigs = {
  'event': _TypeConfig(
      icon: '📅',
      label: 'Event',
      color: Color(0xFF2dd4a0),
      bg: Color(0xFF0d3b2e)),
  'exhibition': _TypeConfig(
      icon: '🖼️',
      label: 'Exhibition',
      color: Color(0xFF60a5fa),
      bg: Color(0xFF1e2d4a)),
  'music': _TypeConfig(
      icon: '🎵',
      label: 'Music',
      color: Color(0xFFc084fc),
      bg: Color(0xFF2d1b4e)),
};

// ── Show item model ──

class _ShowItem {
  final String id, type, title, subType, dateStr, location;
  final String? imageUrl;
  final bool isFree;
  final int sortDate;
  _ShowItem(
      {required this.id,
      required this.type,
      required this.title,
      this.subType = '',
      this.dateStr = '',
      this.location = '',
      this.imageUrl,
      this.isFree = false,
      this.sortDate = 0});
}

// ── Main Screen ──

class ShowsScreen extends StatefulWidget {
  const ShowsScreen({super.key});
  @override
  State<ShowsScreen> createState() => _ShowsScreenState();
}

class _ShowsScreenState extends State<ShowsScreen> {
  final _showsService = ShowsService();
  List<_ShowItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = <_ShowItem>[];
    final df = DateFormat('MMM d');

    final results = await Future.wait([
      _showsService.fetchEvents(),
      _showsService.fetchExhibitions(),
    ]);

    final events = results[0];
    final exhibitions = results[1];

    for (final e in events) {
      final d = e['date'] ?? e['startDate'];
      final isMusicShow = e['category'] == 'music';
      final subType = (e['type'] as String?)?.replaceAll('_', ' ') ?? '';
      final dateStr = d != null ? df.format(DateTime.parse(d)) : '';
      final sortDate = d != null ? DateTime.parse(d).millisecondsSinceEpoch : 0;
      final cover = e['coverImage'];
      final imageUrl = cover is Map ? cover['url']?.toString() : null;
      all.add(_ShowItem(
          id: e['_id'] ?? '',
          type: isMusicShow ? 'music' : 'event',
          title: e['title'] ?? '',
          subType: subType,
          dateStr: dateStr,
          location: e['location'] ?? '',
          imageUrl: imageUrl,
          isFree: e['isFree'] == true,
          sortDate: sortDate));
    }

    for (final e in exhibitions) {
      final d = e['startDate'];
      var dateStr = '';
      if (d != null) {
        dateStr = df.format(DateTime.parse(d));
        if (e['endDate'] != null)
          dateStr += ' – ${df.format(DateTime.parse(e['endDate']))}';
      }
      final sortDate = d != null ? DateTime.parse(d).millisecondsSinceEpoch : 0;
      final cover = e['coverImage'];
      final imageUrl = cover is Map ? cover['url']?.toString() : null;
      all.add(_ShowItem(
          id: e['_id'] ?? '',
          type: 'exhibition',
          title: e['title'] ?? '',
          subType: e['status'] ?? '',
          dateStr: dateStr,
          location: e['location'] ?? '',
          imageUrl: imageUrl,
          isFree: e['isFree'] == true,
          sortDate: sortDate));
    }

    all.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    if (mounted)
      setState(() {
        _items = all;
        _loading = false;
      });
  }

  void _push(Widget screen) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _handleCreateShow() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      _push(const LoginScreen());
      return;
    }
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(builder: (_) => const CreateShowScreen()))
        .then((created) {
      if (created == true) _load();
    });
  }

  void _handleItemPress(_ShowItem item) {
    if (item.type == 'event' || item.type == 'music') {
      _push(EventDetailScreen(id: item.id));
    } else if (item.type == 'exhibition') {
      _push(ExhibitionDetailScreen(id: item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(
          body:
              Center(child: CircularProgressIndicator(color: AppColors.teal)));

    int eventCount = 0, exhibitionCount = 0, musicCount = 0;
    for (final i in _items) {
      if (i.type == 'event')
        eventCount++;
      else if (i.type == 'exhibition')
        exhibitionCount++;
      else if (i.type == 'music') musicCount++;
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Nav Buttons ──
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.borderLight))),
                child: Row(children: [
                  _navButton('📅', 'Events', eventCount,
                      () => _push(const EventsScreen())),
                  const SizedBox(width: AppSpacing.sm),
                  _navButton('🖼️', 'Exhibitions', exhibitionCount,
                      () => _push(const ExhibitionsScreen())),
                  const SizedBox(width: AppSpacing.sm),
                  _navButton('🎵', 'Music', musicCount,
                      () => _push(const MusicScreen())),
                ]),
              ),
            ),

            // ── Timeline ──
            if (_items.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md + AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm),
                  child: const Text('UPCOMING & RECENT',
                      style: TextStyle(
                          fontSize: AppFontSize.xxs,
                          letterSpacing: 2,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (context, index) => _showRow(_items[index]),
                        childCount: _items.length)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ] else ...[
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                    child:
                        Column(mainAxisSize: MainAxisSize.min, children: const [
                  Text('🎭', style: TextStyle(fontSize: 40)),
                  SizedBox(height: AppSpacing.md),
                  Text('No shows yet',
                      style: TextStyle(
                          fontSize: AppFontSize.lg,
                          color: AppColors.textSecondary)),
                  SizedBox(height: AppSpacing.sm),
                  Text('Create an event, exhibition, or music show',
                      style: TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textMuted)),
                ])),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: [
              BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: FloatingActionButton.extended(
          onPressed: _handleCreateShow,
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.textInverse,
          icon: const Text('+',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          label: const Text('New Show',
              style: TextStyle(
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3)),
        ),
      ),
    );
  }

  Widget _navButton(String icon, String label, int count, VoidCallback onTap) {
    return Expanded(
        child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderLight)),
              child: Column(children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: AppFontSize.xs,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                if (count > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(AppRadius.full)),
                    child: Center(
                        child: Text('$count',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textInverse,
                                fontWeight: FontWeight.w700))),
                  ),
                ],
              ]),
            )));
  }

  Widget _showRow(_ShowItem item) {
    final cfg = _typeConfigs[item.type] ?? _typeConfigs['event']!;
    return GestureDetector(
      onTap: () => _handleItemPress(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderLight))),
        child: Row(children: [
          if (item.imageUrl != null)
            ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(item.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _iconThumb(cfg)))
          else
            _iconThumb(cfg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text)),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: cfg.color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(
                    [
                      cfg.label,
                      if (item.subType.isNotEmpty) item.subType,
                      if (item.dateStr.isNotEmpty) item.dateStr,
                      if (item.location.isNotEmpty) item.location
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: AppFontSize.xs, color: AppColors.textMuted),
                  )),
                ]),
              ])),
          if (item.isFree)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.teal),
                  borderRadius: BorderRadius.circular(AppRadius.full)),
              child: const Text('Free',
                  style: TextStyle(
                      fontSize: 9,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600)),
            ),
          const Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: Text('›',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: AppFontSize.sm))),
        ]),
      ),
    );
  }

  Widget _iconThumb(_TypeConfig cfg) {
    return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            color: cfg.bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Center(
            child: Text(cfg.icon, style: const TextStyle(fontSize: 16))));
  }
}
