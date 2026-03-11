// lib/screens/shows/events_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _api = ApiService();
  List<dynamic> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get(ApiConfig.events);
      final data = res.data as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>? ?? []);
      setState(() {
        _events = list.where((e) => e['category'] != 'music').toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Events load error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Events'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : _events.isEmpty
              ? Center(
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: const [
                  Text('📅', style: TextStyle(fontSize: 40)),
                  SizedBox(height: AppSpacing.md),
                  Text('No events yet',
                      style: TextStyle(
                          fontSize: AppFontSize.lg,
                          color: AppColors.textSecondary)),
                ]))
              : RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final e = _events[index] as Map<String, dynamic>;
                      final d = e['date'] ?? e['startDate'];
                      final dateStr = d != null
                          ? DateFormat('MMM d').format(DateTime.parse(d))
                          : '';
                      final cover = e['coverImage'];
                      final img =
                          cover is Map ? cover['url']?.toString() : null;
                      return GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    EventDetailScreen(id: e['_id']))),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md),
                          decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: AppColors.borderLight))),
                          child: Row(children: [
                            if (img != null)
                              ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        if (dateStr.isNotEmpty) dateStr,
                                        if (e['location'] != null) e['location']
                                      ].join('  ·  '),
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: AppFontSize.xs)),
                                ])),
                            const Text('›',
                                style: TextStyle(color: AppColors.textMuted)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _thumb() => Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          color: const Color(0xFF0d3b2e),
          borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: const Center(child: Text('📅', style: TextStyle(fontSize: 16))));
}
