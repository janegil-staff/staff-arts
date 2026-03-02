// lib/screens/explore/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/artwork_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/artwork_card.dart';
import '../../widgets/section_header.dart';
import '../artwork/artwork_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  String _selectedMedium = 'all';
  bool _searchMode = false;

  final _mediums = [
    'all',
    'painting',
    'sculpture',
    'photography',
    'digital',
    'mixed media'
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<ArtworkProvider>();
    provider.fetchFeatured();
    provider.fetchArtworks(refresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArtworkProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final colWidth = (screenWidth - AppSpacing.lg * 2 - AppSpacing.sm) / 2;

    return Column(
      children: [
        // ── Search Bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Search artworks & artists...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchMode = false);
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) {
                    setState(() => _searchMode = v.trim().isNotEmpty);
                  },
                  onSubmitted: (_) {
                    provider.fetchArtworks(refresh: true, filters: {
                      if (_searchController.text.trim().isNotEmpty)
                        'search': _searchController.text.trim(),
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () {
                  // TODO: show filter modal
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
                    child: Icon(Icons.tune,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Medium Chips ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: _mediums.map((m) {
              final label = m == 'mixed media'
                  ? 'Mixed'
                  : m[0].toUpperCase() + m.substring(1);
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppChip(
                  label: label,
                  active: _selectedMedium == m,
                  onTap: () {
                    setState(() => _selectedMedium = m);
                    provider.fetchArtworks(refresh: true, filters: {
                      if (m != 'all') 'medium': m,
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // ── Content ──
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await provider.fetchFeatured();
              await provider.fetchArtworks(refresh: true);
            },
            color: AppColors.teal,
            backgroundColor: AppColors.surface,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                // Trending (when not searching)
                if (!_searchMode && provider.featured.isNotEmpty) ...[
                  const SectionHeader(label: 'Trending'),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: AppSpacing.lg),
                      itemCount: provider.featured.length,
                      itemBuilder: (context, index) {
                        final artwork = provider.featured[index];
                        return FeaturedArtworkCard(
                          artwork: artwork,
                          cardWidth: 160,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ArtworkDetailScreen(artwork: artwork),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Results count when searching
                if (_searchMode)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      '${provider.artworks.length} artwork${provider.artworks.length != 1 ? 's' : ''} found',
                      style: const TextStyle(
                        fontSize: AppFontSize.xs,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),

                // Grid
                if (provider.artworks.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.md,
                      children: provider.artworks.map((artwork) {
                        return ArtworkCard(
                          artwork: artwork,
                          width: colWidth,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ArtworkDetailScreen(artwork: artwork),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Empty
                if (provider.artworks.isEmpty && !provider.loading)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _searchMode ? 'No results' : 'No artworks found',
                            style: const TextStyle(
                              fontSize: AppFontSize.lg,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _searchMode
                                ? 'Try a different search or adjust your filters'
                                : 'Check back soon for new work',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (provider.loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.teal, strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
