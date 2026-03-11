// lib/screens/shows/music_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/shows_service.dart';
import '../../config/api_config.dart';
import 'event_detail_screen.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final _service = ShowsService();
  List<dynamic> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _service.fetchEvents();
      setState(() {
        _events = all.where((e) => e['category'] == 'music').toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Music events load error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: const Text('Music',
            style: TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.w200,
                letterSpacing: 1)),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Text('${_events.length} events',
                    style: const TextStyle(
                        fontSize: AppFontSize.sm, color: AppColors.textMuted)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : _events.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _events.length,
                    itemBuilder: (context, index) => _buildRow(_events[index]),
                  ),
                ),
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
          const Text('No music events yet',
              style: TextStyle(
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.xs),
          const Text('Music events will appear here',
              style: TextStyle(
                  fontSize: AppFontSize.sm, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildRow(dynamic item) {
    if (item is! Map<String, dynamic>) return const SizedBox.shrink();
    final e = item;
    final d = e['date'] ?? e['startDate'];
    final dateStr =
        d != null ? DateFormat('MMM d').format(DateTime.parse(d)) : '';
    final cover = e['coverImage'];
    final img = cover is Map ? cover['url']?.toString() : null;
    final subType = (e['type'] as String?)?.replaceAll('_', ' ') ?? '';

    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => EventDetailScreen(id: e['_id']))),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderLight))),
        child: Row(children: [
          if (img != null)
            ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(img,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumb()))
          else
            _thumb(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(e['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w500,
                        fontSize: AppFontSize.md)),
                const SizedBox(height: 3),
                Text(
                    [
                      if (subType.isNotEmpty) subType,
                      if (dateStr.isNotEmpty) dateStr,
                      if (e['location'] != null &&
                          e['location'].toString().isNotEmpty)
                        e['location'],
                    ].join('  ·  '),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: AppFontSize.xs)),
              ])),
          if (e['isFree'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.teal),
                  borderRadius: BorderRadius.circular(AppRadius.full)),
              child: const Text('Free',
                  style: TextStyle(
                      fontSize: 9,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600)),
            ),
          const Text('›', style: TextStyle(color: AppColors.textMuted)),
        ]),
      ),
    );
  }

  Widget _thumb() => Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          color: const Color(0xFF2d1b4e),
          borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: const Center(child: Text('🎵', style: TextStyle(fontSize: 16))));
}
