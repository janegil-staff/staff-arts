// lib/screens/artwork/saved_artworks_screen.dart
import 'package:flutter/material.dart';
import '../../models/artwork_model.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artwork_card.dart';
import 'artwork_detail_screen.dart';

class SavedArtworksScreen extends StatefulWidget {
  const SavedArtworksScreen({super.key});

  @override
  State<SavedArtworksScreen> createState() => _SavedArtworksScreenState();
}

class _SavedArtworksScreenState extends State<SavedArtworksScreen> {
  final _api = ApiService();
  final _scrollController = ScrollController();
  List<ArtworkModel> _artworks = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _page = 1;
      _hasMore = true;
      _artworks = [];
    });
    try {
      final res = await _api.get(ApiConfig.artworksSaved,
          params: {'page': 1, 'limit': 20});
      final list = res.data['data'] as List? ?? [];
      setState(() {
        _artworks =
            list.map<ArtworkModel>((j) => ArtworkModel.fromJson(j)).toList();
        _hasMore = res.data['hasMore'] == true;
        _page = 2;
      });
    } catch (e) {
      debugPrint('SavedArtworks load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final res = await _api.get(ApiConfig.artworksSaved,
          params: {'page': _page, 'limit': 20});
      final list = res.data['data'] as List? ?? [];
      setState(() {
        _artworks.addAll(
            list.map<ArtworkModel>((j) => ArtworkModel.fromJson(j)).toList());
        _hasMore = res.data['hasMore'] == true;
        _page++;
      });
    } catch (_) {}
    if (mounted) setState(() => _loadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colWidth = (screenWidth - AppSpacing.lg * 2 - AppSpacing.sm) / 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Artworks',
            style: TextStyle(fontWeight: FontWeight.w300)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))
          : _artworks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDim,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Icon(Icons.bookmark_border_rounded,
                            size: 32, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text('No saved artworks yet',
                          style: TextStyle(
                              fontSize: AppFontSize.lg,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text)),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('Bookmark artworks to find them here',
                          style: TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.teal,
                  backgroundColor: AppColors.surface,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100),
                        sliver: SliverToBoxAdapter(
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
                                        ArtworkDetailScreen(artwork: artwork),
                                  ),
                                ).then((_) => _load()),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (_loadingMore)
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: 40),
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: AppColors.teal, strokeWidth: 2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
