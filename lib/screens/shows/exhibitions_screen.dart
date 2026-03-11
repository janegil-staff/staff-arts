// lib/screens/shows/exhibitions_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'exhibition_detail_screen.dart';

class ExhibitionsScreen extends StatefulWidget {
  const ExhibitionsScreen({super.key});
  @override
  State<ExhibitionsScreen> createState() => _ExhibitionsScreenState();
}

class _ExhibitionsScreenState extends State<ExhibitionsScreen> {
  final _api = ApiService();
  List<dynamic> _exhibitions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get(ApiConfig.exhibitions);
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _exhibitions = (data['data'] as List<dynamic>? ?? []);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Exhibitions load error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Exhibitions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : _exhibitions.isEmpty
              ? Center(
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: const [
                  Text('🖼️', style: TextStyle(fontSize: 40)),
                  SizedBox(height: AppSpacing.md),
                  Text('No exhibitions yet',
                      style: TextStyle(
                          fontSize: AppFontSize.lg,
                          color: AppColors.textSecondary)),
                ]))
              : RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _exhibitions.length,
                    itemBuilder: (context, index) {
                      final e = _exhibitions[index] as Map<String, dynamic>;
                      final d = e['startDate'];
                      var dateStr = '';
                      if (d != null) {
                        dateStr = DateFormat('MMM d').format(DateTime.parse(d));
                        if (e['endDate'] != null)
                          dateStr +=
                              ' – ${DateFormat('MMM d').format(DateTime.parse(e['endDate']))}';
                      }
                      final cover = e['coverImage'];
                      final img = cover is Map
                          ? cover['url']?.toString()
                          : (cover is String && cover.isNotEmpty
                              ? cover
                              : null);
                      return GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ExhibitionDetailScreen(id: e['_id']))),
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
                            if (e['status'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                margin:
                                    const EdgeInsets.only(right: AppSpacing.sm),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF1e2d4a),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full)),
                                child: Text(e['status'],
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF60a5fa),
                                        fontWeight: FontWeight.w600)),
                              ),
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
          color: const Color(0xFF1e2d4a),
          borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: const Center(child: Text('🖼️', style: TextStyle(fontSize: 16))));
}
