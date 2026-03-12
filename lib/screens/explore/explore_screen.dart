// lib/screens/explore/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/artwork_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/artwork_card.dart';
import '../artwork/artwork_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedMedium = 'all';
  bool _searchMode = false;
  bool _showFilterRow = true;
  double _lastOffset = 0;

  // final _mediums = [
  //   'all',
  //   'painting',
  //   'sculpture',
  //   'photography',
  //   'digital',
  //   'mixed media',
  // ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArtworkProvider>().fetchArtworks(refresh: true);
      context.read<ArtworkProvider>().fetchMediums(); // <-- ny
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    // Auto-hide filter chips on scroll down, show on scroll up
    if (offset > _lastOffset && offset > 60 && _showFilterRow) {
      setState(() => _showFilterRow = false);
    } else if (offset < _lastOffset && !_showFilterRow) {
      setState(() => _showFilterRow = true);
    }
    _lastOffset = offset;

    // Infinite scroll
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ArtworkProvider>();
      if (!provider.loading) {
        provider.fetchArtworks();
      }
    }
  }

  void _onMediumSelected(String medium) {
    setState(() => _selectedMedium = medium);
    context.read<ArtworkProvider>().fetchArtworks(refresh: true, filters: {
      if (medium != 'all') 'medium': medium,
      if (_searchController.text.trim().isNotEmpty)
        'search': _searchController.text.trim(),
    });
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    context.read<ArtworkProvider>().fetchArtworks(refresh: true, filters: {
      if (query.isNotEmpty) 'search': query,
      if (_selectedMedium != 'all') 'medium': _selectedMedium,
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArtworkProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // ── Search ──
        _buildSearchBar(),

        // ── Filter chips ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          height: _showFilterRow ? 52 : 0,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: _buildFilterChips(),
        ),

        // ── Results ──
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await context
                  .read<ArtworkProvider>()
                  .fetchArtworks(refresh: true, filters: {
                if (_selectedMedium != 'all') 'medium': _selectedMedium,
                if (_searchController.text.trim().isNotEmpty)
                  'search': _searchController.text.trim(),
              });
            },
            color: AppColors.teal,
            backgroundColor: AppColors.surface,
            child: _buildBody(provider, screenWidth),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search artworks, artists, styles...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchMode = false);
                          context
                              .read<ArtworkProvider>()
                              .fetchArtworks(refresh: true, filters: {
                            if (_selectedMedium != 'all')
                              'medium': _selectedMedium,
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDim,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                            size: 14,
                          ),
                        ),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) {
                setState(() => _searchMode = v.trim().isNotEmpty);
              },
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              // TODO: filter modal
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Icon(
                  Icons.tune_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final mediums = ['all', ...context.watch<ArtworkProvider>().mediums];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: mediums.map((m) {
          final label = m == 'all' ? 'All' : m;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: AppChip(
              label: label,
              active: _selectedMedium == m,
              onTap: () => _onMediumSelected(m),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(ArtworkProvider provider, double screenWidth) {
    if (provider.loading && provider.artworks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.teal,
          strokeWidth: 2,
        ),
      );
    }

    if (provider.artworks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: screenWidth * 0.4),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Icon(
                    _searchMode
                        ? Icons.search_off_rounded
                        : Icons.palette_outlined,
                    size: 32,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _searchMode ? 'No results found' : 'No artworks yet',
                  style: const TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _searchMode
                      ? 'Try different keywords or filters'
                      : 'New work will appear here soon',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Staggered 2-column layout
    final padding = AppSpacing.lg;
    final gap = AppSpacing.sm;
    final colWidth = (screenWidth - padding * 2 - gap) / 2;

    final leftCol = <int>[];
    final rightCol = <int>[];
    double leftH = 0;
    double rightH = 0;

    for (int i = 0; i < provider.artworks.length; i++) {
      // Alternate heights for visual interest
      final ratio = i % 3 == 0 ? 1.4 : (i % 3 == 1 ? 1.1 : 1.25);
      final cardH = colWidth * ratio + 60; // image + text

      if (leftH <= rightH) {
        leftCol.add(i);
        leftH += cardH + gap;
      } else {
        rightCol.add(i);
        rightH += cardH + gap;
      }
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Result count when searching
        if (_searchMode)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${provider.artworks.length} result${provider.artworks.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: AppFontSize.xs,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

        // Two-column masonry grid
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.xs, padding, 100),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                SizedBox(
                  width: colWidth,
                  child: Column(
                    children: leftCol.map((i) {
                      final artwork = provider.artworks[i];
                      final ratio =
                          i % 3 == 0 ? 1.4 : (i % 3 == 1 ? 1.1 : 1.25);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildMasonryCard(artwork, colWidth, ratio),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(width: gap),
                // Right column
                SizedBox(
                  width: colWidth,
                  child: Column(
                    children: rightCol.map((i) {
                      final artwork = provider.artworks[i];
                      final ratio =
                          i % 3 == 0 ? 1.4 : (i % 3 == 1 ? 1.1 : 1.25);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildMasonryCard(artwork, colWidth, ratio),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Loading more indicator
        if (provider.loading)
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 40),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.teal,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMasonryCard(dynamic artwork, double width, double ratio) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtworkDetailScreen(artwork: artwork),
        ),
      ),
      child: ArtworkCard(
        artwork: artwork,
        width: width,
      ),
    );
  }
}
