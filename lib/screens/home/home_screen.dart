// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/artwork_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/artwork_card.dart';
import '../../widgets/section_header.dart';
import '../artwork/artwork_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ArtworkProvider>();
    provider.fetchFeatured();
    provider.fetchArtworks(refresh: true);
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    final provider = context.read<ArtworkProvider>();
    await Future.wait([
      provider.fetchFeatured(),
      provider.fetchArtworks(refresh: true),
    ]);
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<ArtworkProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final featuredCardWidth = screenWidth * 0.72;

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

          // ── Curated (Featured) ──
          if (provider.featured.isNotEmpty) ...[
            SectionHeader(
              label: 'Curated',
              actionText: 'See all',
              onAction: () {
                // Navigate to Explore tab
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: featuredCardWidth * 1.15 + 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                physics: const BouncingScrollPhysics(),
                itemCount: provider.featured.length,
                itemBuilder: (context, index) {
                  final artwork = provider.featured[index];
                  return FeaturedArtworkCard(
                    artwork: artwork,
                    cardWidth: featuredCardWidth,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtworkDetailScreen(artwork: artwork),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ── Just Added (Recent Grid) ──
          if (provider.artworks.isNotEmpty) ...[
            const SectionHeader(label: 'Just Added'),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildRecentGrid(provider, screenWidth),
            ),
          ],

          // ── Empty State ──
          if (provider.featured.isEmpty &&
              provider.artworks.isEmpty &&
              !provider.loading) ...[
            const SizedBox(height: 60),
            const Center(
              child: Column(
                children: [
                  Text('🎨', style: TextStyle(fontSize: 48)),
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
